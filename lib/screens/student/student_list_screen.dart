import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../models/faculty_data.dart';
import '../../services/firebase_service.dart';
import '../../utils/logging/logger.dart';
import '../../config/app_config.dart';
import '../../data/demo_data.dart';
import 'add_edit_student_screen.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen>
    with AutomaticKeepAliveClientMixin {
  List<Student> students = [];
  bool isLoading = true;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  String? sortOption;
  
  // Filter options
  String? selectedFaculty;
  String? selectedStudyProgram;
  String? selectedVehicleType;
  bool showFilters = false;
  
  // Available filter values
  List<String> availableFaculties = [];
  List<String> availableStudyPrograms = [];
  List<String> availableVehicleTypes = [];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Student> fetchedStudents;
      if (AppConfig.isDevelopment) {
        await Future.delayed(const Duration(milliseconds: 500));
        fetchedStudents = DemoData.getAllStudents();
      } else {
        fetchedStudents = await FirebaseService.getAllStudents();
      }

      // Update available filter options
      _updateFilterOptions(fetchedStudents);

      students = fetchedStudents;
    } catch (e) {
      Logger.error('Error loading students: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error loading students: $e')),
              ],
            ),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _updateFilterOptions(List<Student> students) {
    // Use predefined faculty data from FacultyData
    availableFaculties = FacultyData.getFaculties();
    
    // Get all study programs from all faculties
    availableStudyPrograms = [];
    for (String faculty in availableFaculties) {
      availableStudyPrograms.addAll(FacultyData.getAllStudyPrograms(faculty));
    }
    availableStudyPrograms = availableStudyPrograms.toSet().toList()..sort();
    
    // Keep vehicle types from actual student data
    availableVehicleTypes = students
        .map((s) => s.vehicleType)
        .where((vt) => vt.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  void _clearAllFilters() {
    setState(() {
      searchQuery = '';
      selectedFaculty = null;
      selectedStudyProgram = null;
      selectedVehicleType = null;
      sortOption = null;
      searchController.clear();
    });
  }

  bool get hasActiveFilters {
    return searchQuery.isNotEmpty ||
        selectedFaculty != null ||
        selectedStudyProgram != null ||
        selectedVehicleType != null ||
        sortOption != null;
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (searchQuery.isNotEmpty) count++;
    if (selectedFaculty != null) count++;
    if (selectedStudyProgram != null) count++;
    if (selectedVehicleType != null) count++;
    if (sortOption != null) count++;
    return count;
  }


  Future<void> _deleteStudent(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('Konfirmasi Hapus'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yakin ingin menghapus mahasiswa berikut?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'NIM: ${student.nim}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data yang dihapus tidak dapat dikembalikan.',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[500],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        bool success;
        if (AppConfig.isDevelopment) {
          DemoData.removeStudent(student.nim);
          success = true;
        } else {
          success = await FirebaseService.deleteStudent(student.nim);
        }

        if (success) {
          await _loadStudents();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('Mahasiswa berhasil dihapus'),
                  ],
                ),
                backgroundColor: Colors.green[500],
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('Gagal menghapus mahasiswa'),
                  ],
                ),
                backgroundColor: Colors.red[400],
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        }
      } catch (e) {
        Logger.error('Error deleting student: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Error: $e')),
                ],
              ),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  List<Student> get filteredStudents {
    List<Student> filtered = List.from(students);

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((student) {
        return student.name.toLowerCase().contains(query) ||
            student.nim.toLowerCase().contains(query) ||
            student.vehicleNumber.toLowerCase().contains(query) ||
            student.faculty.toLowerCase().contains(query) ||
            student.studyProgram.toLowerCase().contains(query);
      }).toList();
    }

    // Apply faculty filter
    if (selectedFaculty != null) {
      filtered = filtered.where((student) => student.faculty == selectedFaculty).toList();
    }

    // Apply study program filter
    if (selectedStudyProgram != null) {
      filtered = filtered.where((student) => student.studyProgram == selectedStudyProgram).toList();
    }

    // Apply vehicle type filter
    if (selectedVehicleType != null) {
      filtered = filtered.where((student) => student.vehicleType == selectedVehicleType).toList();
    }

    // Apply sorting
    if (sortOption != null) {
      switch (sortOption) {
        case 'name_asc':
          filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case 'name_desc':
          filtered.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
          break;
        case 'nim_asc':
          filtered.sort((a, b) => a.nim.compareTo(b.nim));
          break;
        case 'nim_desc':
          filtered.sort((a, b) => b.nim.compareTo(a.nim));
          break;
        case 'faculty_asc':
          filtered.sort((a, b) => a.faculty.toLowerCase().compareTo(b.faculty.toLowerCase()));
          break;
        case 'faculty_desc':
          filtered.sort((a, b) => b.faculty.toLowerCase().compareTo(a.faculty.toLowerCase()));
          break;
        case 'scan_time_newest':
          filtered.sort((a, b) => b.scanTime.compareTo(a.scanTime));
          break;
        case 'scan_time_oldest':
          filtered.sort((a, b) => a.scanTime.compareTo(b.scanTime));
          break;
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Compact Modern Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    // Icon with modern design
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Mahasiswa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kelola data mahasiswa dan kendaraan',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Statistics badge
                    if (!isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.group,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${students.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadStudents,
              color: Theme.of(context).colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Modern Search Bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari mahasiswa...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        searchQuery = '';
                                        searchController.clear();
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),

                    // Modern Filter and Sort Controls
                    if (!isLoading) ...[
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Row(
                          children: [
                            // Filter Button
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      showFilters = !showFilters;
                                    });
                                  },
                                  icon: Icon(
                                    showFilters ? Icons.filter_list_off : Icons.tune,
                                    size: 18,
                                  ),
                                  label: Text(
                                    hasActiveFilters 
                                        ? 'Filter (${_getActiveFilterCount()})'
                                        : 'Filter',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: hasActiveFilters 
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.white,
                                    foregroundColor: hasActiveFilters 
                                        ? Colors.white
                                        : Colors.grey[700],
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: hasActiveFilters 
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey[200]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Sort Button
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    setState(() {
                                      sortOption = value;
                                    });
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: null,
                                      child: Row(
                                        children: [
                                          Icon(Icons.clear, size: 18),
                                          SizedBox(width: 8),
                                          Text('Hapus Urutan'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                      value: 'name_asc',
                                      child: Row(
                                        children: [
                                          Icon(Icons.sort_by_alpha, size: 18),
                                          SizedBox(width: 8),
                                          Text('Nama A-Z'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'name_desc',
                                      child: Row(
                                        children: [
                                          Icon(Icons.sort_by_alpha, size: 18),
                                          SizedBox(width: 8),
                                          Text('Nama Z-A'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'nim_asc',
                                      child: Row(
                                        children: [
                                          Icon(Icons.numbers, size: 18),
                                          SizedBox(width: 8),
                                          Text('NIM A-Z'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'nim_desc',
                                      child: Row(
                                        children: [
                                          Icon(Icons.numbers, size: 18),
                                          SizedBox(width: 8),
                                          Text('NIM Z-A'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'faculty_asc',
                                      child: Row(
                                        children: [
                                          Icon(Icons.school, size: 18),
                                          SizedBox(width: 8),
                                          Text('Fakultas A-Z'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'faculty_desc',
                                      child: Row(
                                        children: [
                                          Icon(Icons.school, size: 18),
                                          SizedBox(width: 8),
                                          Text('Fakultas Z-A'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'scan_time_newest',
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time, size: 18),
                                          SizedBox(width: 8),
                                          Text('Terbaru'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'scan_time_oldest',
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time, size: 18),
                                          SizedBox(width: 8),
                                          Text('Terlama'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sortOption != null 
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: sortOption != null 
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey[200]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.sort,
                                          size: 18,
                                          color: sortOption != null 
                                              ? Colors.white
                                              : Colors.grey[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          sortOption != null ? 'Diurutkan' : 'Urutkan',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: sortOption != null 
                                                ? Colors.white
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Filter Options (Expandable)
                      if (showFilters) ...[
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.tune,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Filter Data',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (hasActiveFilters)
                                    TextButton.icon(
                                      onPressed: _clearAllFilters,
                                      icon: const Icon(Icons.clear_all, size: 16),
                                      label: const Text('Hapus Semua'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red[600],
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Faculty Filter
                              if (availableFaculties.isNotEmpty) ...[
                                const Text(
                                  'Fakultas',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[200]!),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedFaculty,
                                      hint: const Text('Pilih Fakultas'),
                                      isExpanded: true,
                                      items: [
                                        const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('Semua Fakultas'),
                                        ),
                                        ...availableFaculties.map((faculty) =>
                                            DropdownMenuItem<String>(
                                              value: faculty,
                                              child: Text(faculty),
                                            )),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          selectedFaculty = value;
                                          // Reset study program when faculty changes
                                          if (selectedStudyProgram != null && selectedFaculty != null) {
                                            final facultyPrograms = FacultyData.getAllStudyPrograms(selectedFaculty!);
                                            if (!facultyPrograms.contains(selectedStudyProgram)) {
                                              selectedStudyProgram = null;
                                            }
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Study Program Filter
                              if (availableStudyPrograms.isNotEmpty) ...[
                                const Text(
                                  'Program Studi',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[200]!),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedStudyProgram,
                                      hint: const Text('Pilih Program Studi'),
                                      isExpanded: true,
                                      items: [
                                        const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('Semua Program Studi'),
                                        ),
                                        // Show only programs from selected faculty if faculty is selected
                                        ...(selectedFaculty != null 
                                            ? FacultyData.getAllStudyPrograms(selectedFaculty!)
                                            : availableStudyPrograms)
                                            .map((program) =>
                                            DropdownMenuItem<String>(
                                              value: program,
                                              child: Text(program),
                                            )),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          selectedStudyProgram = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Vehicle Type Filter
                              if (availableVehicleTypes.isNotEmpty) ...[
                                const Text(
                                  'Jenis Kendaraan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[200]!),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedVehicleType,
                                      hint: const Text('Pilih Jenis Kendaraan'),
                                      isExpanded: true,
                                      items: [
                                        const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('Semua Jenis Kendaraan'),
                                        ),
                                        ...availableVehicleTypes.map((type) =>
                                            DropdownMenuItem<String>(
                                              value: type,
                                              child: Text(type),
                                            )),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          selectedVehicleType = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],

                    // Quick Stats Cards
                    if (!isLoading)
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.people_alt_rounded,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 20,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${students.length}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green[600]!,
                                      Colors.green[500]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_rounded,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 20,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${filteredStudents.length}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      'Hasil',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Student List
                    isLoading
                        ? SizedBox(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                    strokeWidth: 3,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Memuat data mahasiswa...',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : filteredStudents.isEmpty
                        ? SizedBox(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      hasActiveFilters
                                          ? Icons.search_off
                                          : Icons.people_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    hasActiveFilters
                                        ? 'Tidak ditemukan mahasiswa'
                                        : 'Belum ada data mahasiswa',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    hasActiveFilters
                                        ? 'Coba ubah filter atau kata kunci pencarian'
                                        : 'Tambahkan mahasiswa baru untuk memulai',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (hasActiveFilters) ...[
                                    const SizedBox(height: 16),
                                    TextButton.icon(
                                      onPressed: _clearAllFilters,
                                      icon: const Icon(Icons.clear_all, size: 18),
                                      label: const Text('Hapus Semua Filter'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: List.generate(filteredStudents.length, (index) {
                              final student = filteredStudents[index];
                              return Container(
                                margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                                child: InkWell(
                                  onTap: () async {
                                    final result = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => StudentDetailScreen(
                                          student: student,
                                        ),
                                      ),
                                    );

                                    if (mounted) {
                                      setState(() {});
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey[100]!,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Avatar
                                          Hero(
                                            tag: 'avatar_${student.nim}',
                                            child: Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Theme.of(context).colorScheme.primary,
                                                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  student.name[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),

                                          // Student Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  student.name,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    student.nim,
                                                    style: TextStyle(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.touch_app,
                                                      size: 12,
                                                      color: Colors.grey[400],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Tap untuk detail',
                                                      style: TextStyle(
                                                        color: Colors.grey[400],
                                                        fontSize: 10,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Action Buttons
                                          Row(
                                            children: [
                                              // Delete Button
                                              IconButton(
                                                onPressed: () => _deleteStudent(student),
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red[400],
                                                  size: 20,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: 'Hapus Mahasiswa',
                                              ),
                                              const SizedBox(width: 8),
                                              // View Details Arrow
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color: Colors.grey[300],
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditStudentScreen(),
            ),
          );
          if (result == true) {
            await _loadStudents();
          }
        },
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Tambah Mahasiswa',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}