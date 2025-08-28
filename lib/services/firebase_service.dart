import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/student.dart';
import '../models/scan_history.dart';
import '../utils/logging/logger.dart';

class FirebaseService {
  static final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://scan-ktm-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();
  
  // Get student by NIM
  static Future<Student?> getStudentByNIM(String nim) async {
    try {
      final snapshot = await _database.child('students/$nim').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return Student.fromFirestore(data);
      }
      return null;
    } catch (e) {
      Logger.error('Error getting student by NIM: $e');
      return null;
    }
  }

  // Get student by vehicle number
  static Future<Student?> getStudentByVehicleNumber(
    String vehicleNumber,
  ) async {
    try {
      final snapshot = await _database.child('students').get();
      if (snapshot.exists) {
        final students = snapshot.value as Map<dynamic, dynamic>;
        for (var entry in students.entries) {
          final studentData = entry.value as Map<dynamic, dynamic>;
          if (studentData['vehicle_number'] == vehicleNumber) {
            return Student.fromFirestore(studentData);
          }
        }
      }
      return null;
    } catch (e) {
      Logger.error('Error getting student by vehicle number: $e');
      return null;
    }
  }

  // Save scan history with scan method
  static Future<bool> saveScanHistory(Student student, String location, {String scanMethod = 'unknown'}) async {
    try {
      final scanData = {
        'student_nim': student.nim,
        'student_name': student.name,
        'faculty': student.faculty,
        'study_program': student.studyProgram,
        'vehicle_number': student.vehicleNumber,
        'vehicle_type': student.vehicleType,
        'scan_time': DateTime.now().millisecondsSinceEpoch,
        'scan_method': scanMethod,
        'location': location,
      };

      await _database.child('scan_history').push().set(scanData);
      Logger.info('Scan history saved for ${student.name} via $scanMethod');
      return true;
    } catch (e) {
      Logger.error('Error saving scan history: $e');
      return false;
    }
  }

  // Get all scan history
  static Future<List<ScanHistory>> getAllScanHistory() async {
    try {
      final snapshot = await _database.child('scan_history').get();
      if (snapshot.exists) {
        final historyData = snapshot.value as Map<dynamic, dynamic>;
        final historyList = <ScanHistory>[];
        
        historyData.forEach((key, value) {
          final history = ScanHistory.fromFirestore(value as Map<dynamic, dynamic>, key);
          historyList.add(history);
        });
        
        // Sort by most recent first
        historyList.sort((a, b) => b.scanTime.compareTo(a.scanTime));
        return historyList;
      }
      return [];
    } catch (e) {
      Logger.error('Error getting scan history: $e');
      return [];
    }
  }

  // Get scan history as Student objects for compatibility
  static Future<List<Student>> getScanHistoryAsStudents() async {
    try {
      final historyList = await getAllScanHistory();
      return historyList.map((history) => history.toStudent()).toList();
    } catch (e) {
      Logger.error('Error getting scan history as students: $e');
      return [];
    }
  }

  // Get all students
  static Future<List<Student>> getAllStudents() async {
    try {
      final snapshot = await _database.child('students').get();
      if (snapshot.exists) {
        final students = snapshot.value as Map<dynamic, dynamic>;
        return students.values
            .map((data) => Student.fromFirestore(data as Map<dynamic, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      Logger.error('Error getting all students: $e');
      return [];
    }
  }

  // Search students by name
  static Future<List<Student>> searchStudentsByName(String query) async {
    try {
      final snapshot = await _database.child('students').get();
      if (snapshot.exists) {
        final students = snapshot.value as Map<dynamic, dynamic>;
        return students.values
            .map((data) => Student.fromFirestore(data as Map<dynamic, dynamic>))
            .where(
              (student) =>
                  student.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
      return [];
    } catch (e) {
      Logger.error('Error searching students: $e');
      return [];
    }
  }

  // Get students by faculty
  static Future<List<Student>> getStudentsByFaculty(String faculty) async {
    try {
      final snapshot = await _database.child('students').get();
      if (snapshot.exists) {
        final students = snapshot.value as Map<dynamic, dynamic>;
        return students.values
            .map((data) => Student.fromFirestore(data as Map<dynamic, dynamic>))
            .where(
              (student) =>
                  student.faculty.toLowerCase().contains(faculty.toLowerCase()),
            )
            .toList();
      }
      return [];
    } catch (e) {
      Logger.error('Error getting students by faculty: $e');
      return [];
    }
  }

  // Get scan statistics
  static Future<Map<String, dynamic>> getScanStatistics() async {
    try {
      final scanHistoryRef = _database.child('scan_history');
      final snapshot = await scanHistoryRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return {
          'total_scans': data.length,
          'today_scans': 0, // TODO: Implement date filtering
          'unique_students': 0, // TODO: Implement unique counting
        };
      }
      return {'total_scans': 0, 'today_scans': 0, 'unique_students': 0};
    } catch (e) {
      Logger.error('Error getting scan statistics: $e');
      return {'total_scans': 0, 'today_scans': 0, 'unique_students': 0};
    }
  }

  // CRUD Operations
  static Future<bool> createStudent(Student student) async {
    try {
      print('=== CREATE STUDENT DEBUG ===');
      print('Student NIM: ${student.nim}');
      print('Student Name: ${student.name}');
      print('Database URL: ${FirebaseDatabase.instance.databaseURL}');
      print('Database Reference: ${_database.path}');

      final studentsRef = _database.child('students');
      print('Students Reference: ${studentsRef.path}');

      final studentData = student.toFirestore();
      print('Student Data to Save: $studentData');

      await studentsRef.child(student.nim).set(studentData);
      print('Student created successfully: ${student.nim}');
      Logger.info('Student created successfully: ${student.nim}');
      return true;
    } catch (e) {
      print('ERROR creating student: $e');
      Logger.error('Error creating student: $e');
      return false;
    }
  }

  static Future<bool> updateStudent(Student student) async {
    try {
      final studentsRef = _database.child('students');
      await studentsRef.child(student.nim).update(student.toFirestore());
      Logger.info('Student updated successfully: ${student.nim}');
      return true;
    } catch (e) {
      Logger.error('Error updating student: $e');
      return false;
    }
  }

  static Future<bool> deleteStudent(String nim) async {
    try {
      final studentsRef = _database.child('students');
      await studentsRef.child(nim).remove();
      Logger.info('Student deleted successfully: $nim');
      return true;
    } catch (e) {
      Logger.error('Error deleting student: $e');
      return false;
    }
  }
}