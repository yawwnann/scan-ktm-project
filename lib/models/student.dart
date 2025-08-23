class Student {
  final String nim;
  final String name;
  final String faculty;
  final String studyProgram;
  final String vehicleNumber;
  final String vehicleType;
  final DateTime scanTime;

  Student({
    required this.nim,
    required this.name,
    required this.faculty,
    required this.studyProgram,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.scanTime,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      nim: json['nim'] ?? '',
      name: json['name'] ?? '',
      faculty: json['faculty'] ?? '',
      studyProgram: json['study_program'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      scanTime: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nim': nim,
      'name': name,
      'faculty': faculty,
      'study_program': studyProgram,
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleType,
      'scan_time': scanTime.toIso8601String(),
    };
  }

  // Method untuk Realtime Database
  factory Student.fromFirestore(Map<dynamic, dynamic> data) {
    return Student(
      nim: data['nim']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      faculty: data['faculty']?.toString() ?? '',
      studyProgram: data['study_program']?.toString() ?? '',
      vehicleNumber: data['vehicle_number']?.toString() ?? '',
      vehicleType: data['vehicle_type']?.toString() ?? '',
      scanTime: DateTime.now(),
    );
  }

  // Added for Realtime Database integration
  Map<String, dynamic> toFirestore() {
    return {
      'nim': nim,
      'name': name,
      'faculty': faculty,
      'study_program': studyProgram,
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleType,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // CRUD Operations
  static Student create({
    required String nim,
    required String name,
    required String faculty,
    required String studyProgram,
    required String vehicleNumber,
    required String vehicleType,
  }) {
    return Student(
      nim: nim,
      name: name,
      faculty: faculty,
      studyProgram: studyProgram,
      vehicleNumber: vehicleNumber,
      vehicleType: vehicleType,
      scanTime: DateTime.now(),
    );
  }

  Student copyWith({
    String? nim,
    String? name,
    String? faculty,
    String? studyProgram,
    String? vehicleNumber,
    String? vehicleType,
    DateTime? scanTime,
  }) {
    return Student(
      nim: nim ?? this.nim,
      name: name ?? this.name,
      faculty: faculty ?? this.faculty,
      studyProgram: studyProgram ?? this.studyProgram,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      scanTime: scanTime ?? this.scanTime,
    );
  }

  @override
  String toString() {
    return 'Student(nim: $nim, name: $name, faculty: $faculty, studyProgram: $studyProgram, vehicleNumber: $vehicleNumber, vehicleType: $vehicleType, scanTime: $scanTime)';
  }
}
