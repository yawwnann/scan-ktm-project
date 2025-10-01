import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/student.dart';
import '../models/scan_history.dart';
import '../utils/logging/logger.dart';

class FirebaseService {
  static DatabaseReference? _database;

  // Getter untuk database dengan error handling
  static DatabaseReference get database {
    if (_database == null) {
      try {
        _database = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
              'https://scan-ktm-default-rtdb.asia-southeast1.firebasedatabase.app',
        ).ref();
        Logger.info('Firebase Database initialized successfully');
      } catch (e) {
        Logger.error('Error initializing Firebase Database: $e');
        rethrow;
      }
    }
    return _database!;
  }

  // Method untuk reset database connection (useful for troubleshooting)
  static void resetDatabaseConnection() {
    _database = null;
    Logger.info('Firebase Database connection reset');
  }

  // Method untuk test koneksi Firebase
  static Future<bool> testConnection() async {
    try {
      final testRef = database.child('test');
      await testRef.set({'timestamp': DateTime.now().millisecondsSinceEpoch});
      await testRef.remove();
      Logger.info('Firebase connection test successful');
      return true;
    } on FirebaseException catch (e) {
      Logger.error('Firebase connection test failed: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      Logger.error('Firebase connection test failed: $e');
      return false;
    }
  }

  // Get student by NIM
  static Future<Student?> getStudentByNIM(String nim) async {
    try {
      final snapshot = await database.child('students/$nim').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return Student.fromFirestore(data);
      }
      return null;
    } on FirebaseException catch (e) {
      Logger.error(
        'Firebase Error getting student by NIM: ${e.code} - ${e.message}',
      );
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
      final snapshot = await database.child('students').get();
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
    } on FirebaseException catch (e) {
      Logger.error(
        'Firebase Error getting student by vehicle number: ${e.code} - ${e.message}',
      );
      return null;
    } catch (e) {
      Logger.error('Error getting student by vehicle number: $e');
      return null;
    }
  }

  // Save scan history with scan method
  static Future<bool> saveScanHistory(
    Student student,
    String location, {
    String scanMethod = 'unknown',
  }) async {
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

      await database.child('scan_history').push().set(scanData);
      Logger.info('Scan history saved for ${student.name} via $scanMethod');
      return true;
    } on FirebaseException catch (e) {
      Logger.error(
        'Firebase Error saving scan history: ${e.code} - ${e.message}',
      );
      return false;
    } catch (e) {
      Logger.error('Error saving scan history: $e');
      return false;
    }
  }

  // Get all scan history
  static Future<List<ScanHistory>> getAllScanHistory() async {
    try {
      final snapshot = await database.child('scan_history').get();
      if (snapshot.exists) {
        final historyData = snapshot.value as Map<dynamic, dynamic>;
        final historyList = <ScanHistory>[];

        historyData.forEach((key, value) {
          final history = ScanHistory.fromFirestore(
            value as Map<dynamic, dynamic>,
            key,
          );
          historyList.add(history);
        });

        // Sort by most recent first
        historyList.sort((a, b) => b.scanTime.compareTo(a.scanTime));
        return historyList;
      }
      return [];
    } on FirebaseException catch (e) {
      Logger.error(
        'Firebase Error getting scan history: ${e.code} - ${e.message}',
      );
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
      final snapshot = await database.child('students').get();
      if (snapshot.exists) {
        final students = snapshot.value as Map<dynamic, dynamic>;
        return students.values
            .map((data) => Student.fromFirestore(data as Map<dynamic, dynamic>))
            .toList();
      }
      return [];
    } on FirebaseException catch (e) {
      Logger.error(
        'Firebase Error getting all students: ${e.code} - ${e.message}',
      );
      return [];
    } catch (e) {
      Logger.error('Error getting all students: $e');
      return [];
    }
  }

  // Search students by name
  static Future<List<Student>> searchStudentsByName(String query) async {
    try {
      final snapshot = await database.child('students').get();
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
    } on FirebaseException catch (e) {
      Logger.error(
        'Firebase Error searching students: ${e.code} - ${e.message}',
      );
      return [];
    } catch (e) {
      Logger.error('Error searching students: $e');
      return [];
    }
  }

  // Get students by faculty
  static Future<List<Student>> getStudentsByFaculty(String faculty) async {
    try {
      final snapshot = await database.child('students').get();
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
    } on FirebaseException catch (e) {
      Logger.error(
        'Firebase Error getting students by faculty: ${e.code} - ${e.message}',
      );
      return [];
    } catch (e) {
      Logger.error('Error getting students by faculty: $e');
      return [];
    }
  }

  // Get scan statistics
  static Future<Map<String, dynamic>> getScanStatistics() async {
    try {
      final scanHistoryRef = database.child('scan_history');
      final snapshot = await scanHistoryRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return {
          'total_scans': data.length,
          'today_scans': 0, 
          'unique_students': 0,
        };
      }
      return {'total_scans': 0, 'today_scans': 0, 'unique_students': 0};
    } on FirebaseException catch (e) {
      Logger.error(
        'Firebase Error getting scan statistics: ${e.code} - ${e.message}',
      );
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
      print('Database Reference: ${database.path}');

      final studentsRef = database.child('students');
      print('Students Reference: ${studentsRef.path}');

      final studentData = student.toFirestore();
      print('Student Data to Save: $studentData');

      await studentsRef.child(student.nim).set(studentData);
      print('Student created successfully: ${student.nim}');
      Logger.info('Student created successfully: ${student.nim}');
      return true;
    } on FirebaseException catch (e) {
      print('Firebase ERROR creating student: ${e.code} - ${e.message}');
      Logger.error('Firebase Error creating student: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('ERROR creating student: $e');
      Logger.error('Error creating student: $e');
      return false;
    }
  }

  static Future<bool> updateStudent(Student student) async {
    try {
      final studentsRef = database.child('students');
      await studentsRef.child(student.nim).update(student.toFirestore());
      Logger.info('Student updated successfully: ${student.nim}');
      return true;
    } on FirebaseException catch (e) {
      Logger.error('Firebase Error updating student: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      Logger.error('Error updating student: $e');
      return false;
    }
  }

  static Future<bool> deleteStudent(String nim) async {
    try {
      final studentsRef = database.child('students');
      await studentsRef.child(nim).remove();
      Logger.info('Student deleted successfully: $nim');
      return true;
    } on FirebaseException catch (e) {
      Logger.error('Firebase Error deleting student: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      Logger.error('Error deleting student: $e');
      return false;
    }
  }
}
