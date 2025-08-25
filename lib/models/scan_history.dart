import 'student.dart';

class ScanHistory {
  final String id;
  final String studentNim;
  final String studentName;
  final String faculty;
  final String studyProgram;
  final String vehicleNumber;
  final String vehicleType;
  final DateTime scanTime;
  final String scanMethod; // 'barcode' or 'ocr'
  final String location;

  ScanHistory({
    required this.id,
    required this.studentNim,
    required this.studentName,
    required this.faculty,
    required this.studyProgram,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.scanTime,
    required this.scanMethod,
    this.location = 'Unknown Location',
  });

  factory ScanHistory.fromStudent(
    Student student, {
    required String scanMethod,
    String location = 'Unknown Location',
    String? id,
  }) {
    return ScanHistory(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      studentNim: student.nim,
      studentName: student.name,
      faculty: student.faculty,
      studyProgram: student.studyProgram,
      vehicleNumber: student.vehicleNumber,
      vehicleType: student.vehicleType,
      scanTime: DateTime.now(),
      scanMethod: scanMethod,
      location: location,
    );
  }

  factory ScanHistory.fromJson(Map<String, dynamic> json) {
    return ScanHistory(
      id: json['id'] ?? '',
      studentNim: json['student_nim'] ?? '',
      studentName: json['student_name'] ?? '',
      faculty: json['faculty'] ?? '',
      studyProgram: json['study_program'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      scanTime: DateTime.fromMillisecondsSinceEpoch(json['scan_time'] ?? 0),
      scanMethod: json['scan_method'] ?? 'unknown',
      location: json['location'] ?? 'Unknown Location',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_nim': studentNim,
      'student_name': studentName,
      'faculty': faculty,
      'study_program': studyProgram,
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleType,
      'scan_time': scanTime.millisecondsSinceEpoch,
      'scan_method': scanMethod,
      'location': location,
    };
  }

  // Method untuk Firebase Realtime Database
  factory ScanHistory.fromFirestore(Map<dynamic, dynamic> data, String id) {
    return ScanHistory(
      id: id,
      studentNim: data['student_nim']?.toString() ?? '',
      studentName: data['student_name']?.toString() ?? '',
      faculty: data['faculty']?.toString() ?? '',
      studyProgram: data['study_program']?.toString() ?? '',
      vehicleNumber: data['vehicle_number']?.toString() ?? '',
      vehicleType: data['vehicle_type']?.toString() ?? '',
      scanTime: DateTime.fromMillisecondsSinceEpoch(data['scan_time'] ?? 0),
      scanMethod: data['scan_method']?.toString() ?? 'unknown',
      location: data['location']?.toString() ?? 'Unknown Location',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'student_nim': studentNim,
      'student_name': studentName,
      'faculty': faculty,
      'study_program': studyProgram,
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleType,
      'scan_time': scanTime.millisecondsSinceEpoch,
      'scan_method': scanMethod,
      'location': location,
    };
  }

  // Convert to Student object for compatibility
  Student toStudent() {
    return Student(
      nim: studentNim,
      name: studentName,
      faculty: faculty,
      studyProgram: studyProgram,
      vehicleNumber: vehicleNumber,
      vehicleType: vehicleType,
      scanTime: scanTime,
    );
  }

  @override
  String toString() {
    return 'ScanHistory(id: $id, studentName: $studentName, nim: $studentNim, scanTime: $scanTime, scanMethod: $scanMethod)';
  }
}