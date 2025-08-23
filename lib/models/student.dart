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

  @override
  String toString() {
    return 'Student(nim: $nim, name: $name, faculty: $faculty, studyProgram: $studyProgram, vehicleNumber: $vehicleNumber, vehicleType: $vehicleType)';
  }
}
