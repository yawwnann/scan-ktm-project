import '../models/student.dart';

class DemoData {
  // Data demo mahasiswa untuk testing
  static final List<Student> students = [
    Student(
      nim: '2021001',
      name: 'Ahmad Fauzi',
      faculty: 'Fakultas Teknologi Industri',
      studyProgram: 'Teknik Informatika',
      vehicleNumber: 'AB 1234 CD',
      vehicleType: 'Motor',
      scanTime: DateTime.now(),
    ),
    Student(
      nim: '2021002',
      name: 'Siti Nurhaliza',
      faculty: 'Fakultas Ekonomi dan Bisnis',
      studyProgram: 'Manajemen',
      vehicleNumber: 'AB 5678 EF',
      vehicleType: 'Motor',
      scanTime: DateTime.now(),
    ),
    Student(
      nim: '2021003',
      name: 'Budi Santoso',
      faculty: 'Fakultas Teknologi Industri',
      studyProgram: 'Teknik Mesin',
      vehicleNumber: 'AB 9012 GH',
      vehicleType: 'Mobil',
      scanTime: DateTime.now(),
    ),
    Student(
      nim: '2021004',
      name: 'Dewi Sartika',
      faculty: 'Fakultas Kedokteran',
      studyProgram: 'Pendidikan Dokter',
      vehicleNumber: 'AB 3456 IJ',
      vehicleType: 'Motor',
      scanTime: DateTime.now(),
    ),
    Student(
      nim: '2021005',
      name: 'Rizki Pratama',
      faculty: 'Fakultas Hukum',
      studyProgram: 'Ilmu Hukum',
      vehicleNumber: 'AB 7890 KL',
      vehicleType: 'Mobil',
      scanTime: DateTime.now(),
    ),
  ];

  // Fungsi untuk mencari mahasiswa berdasarkan NIM
  static Student? findStudentByNIM(String nim) {
    try {
      return students.firstWhere((student) => student.nim == nim);
    } catch (e) {
      return null;
    }
  }

  // Fungsi untuk mencari mahasiswa berdasarkan nomor plat
  static Student? findStudentByVehicleNumber(String vehicleNumber) {
    try {
      return students.firstWhere(
        (student) =>
            student.vehicleNumber.toLowerCase() == vehicleNumber.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Fungsi untuk mencari mahasiswa berdasarkan barcode (anggap barcode = NIM)
  static Student? findStudentByBarcode(String barcode) {
    // Untuk demo, anggap barcode sama dengan NIM
    return findStudentByNIM(barcode);
  }

  // Fungsi untuk mendapatkan semua mahasiswa
  static List<Student> getAllStudents() {
    return List.from(students);
  }

  // Fungsi untuk menambah mahasiswa baru
  static void addStudent(Student student) {
    students.add(student);
  }

  // Fungsi untuk menghapus mahasiswa
  static bool removeStudent(String nim) {
    try {
      students.removeWhere((student) => student.nim == nim);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Fungsi untuk update data mahasiswa
  static bool updateStudent(String nim, Student updatedStudent) {
    try {
      final index = students.indexWhere((student) => student.nim == nim);
      if (index != -1) {
        students[index] = updatedStudent;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Fungsi untuk mencari mahasiswa berdasarkan nama (fuzzy search)
  static List<Student> searchStudentsByName(String query) {
    if (query.isEmpty) return [];

    return students.where((student) {
      return student.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Fungsi untuk mendapatkan mahasiswa berdasarkan fakultas
  static List<Student> getStudentsByFaculty(String faculty) {
    return students.where((student) {
      return student.faculty.toLowerCase().contains(faculty.toLowerCase());
    }).toList();
  }

  // Fungsi untuk mendapatkan statistik
  static Map<String, dynamic> getStatistics() {
    final facultyStats = <String, int>{};
    final vehicleTypeStats = <String, int>{};

    for (final student in students) {
      // Statistik fakultas
      facultyStats[student.faculty] = (facultyStats[student.faculty] ?? 0) + 1;

      // Statistik jenis kendaraan
      vehicleTypeStats[student.vehicleType] =
          (vehicleTypeStats[student.vehicleType] ?? 0) + 1;
    }

    return {
      'total_students': students.length,
      'faculty_stats': facultyStats,
      'vehicle_type_stats': vehicleTypeStats,
    };
  }
}
