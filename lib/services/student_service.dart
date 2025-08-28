import '../models/student.dart';
import '../config/app_config.dart';
import '../data/demo_data.dart';
import '../utils/logging/logger.dart';
import '../services/firebase_service.dart';

class StudentService {
  // Fungsi untuk mendapatkan data mahasiswa berdasarkan barcode
  static Future<Student?> getStudentByBarcode(String barcode) async {
    // Gunakan demo data jika dalam mode development
    if (AppConfig.isDevelopment) {
      return DemoData.findStudentByBarcode(barcode);
    }

    // Gunakan Firebase untuk production
    return await FirebaseService.getStudentByNIM(barcode);
  }

  // Fungsi untuk mendapatkan data mahasiswa berdasarkan NIM
  static Future<Student?> getStudentByNIM(String nim) async {
    // Gunakan demo data jika dalam mode development
    if (AppConfig.isDevelopment) {
      return DemoData.findStudentByNIM(nim);
    }

    // Gunakan Firebase untuk production
    return await FirebaseService.getStudentByNIM(nim);
  }

  // Fungsi untuk mendapatkan data mahasiswa berdasarkan nomor plat
  static Future<Student?> getStudentByVehicleNumber(
    String vehicleNumber,
  ) async {
    // Gunakan demo data jika dalam mode development
    if (AppConfig.isDevelopment) {
      return DemoData.findStudentByVehicleNumber(vehicleNumber);
    }

    // Gunakan Firebase untuk production
    return await FirebaseService.getStudentByVehicleNumber(vehicleNumber);
  }

  // Fungsi untuk menyimpan riwayat scanning dengan method scan
  static Future<bool> saveScanHistory(Student student, {String scanMethod = 'unknown'}) async {
    // Gunakan demo data jika dalam mode development
    if (AppConfig.isDevelopment) {
      // Tambahkan ke riwayat scan demo
      DemoData.addScanHistory(student, scanMethod);
      Logger.info('Demo mode: Data scanning disimpan untuk ${student.name} via $scanMethod');
      return true;
    }

    // Gunakan Firebase untuk production
    return await FirebaseService.saveScanHistory(student, 'Campus Gate', scanMethod: scanMethod);
  }

  // Fungsi untuk mendapatkan riwayat scan
  static Future<List<Student>> getScanHistory() async {
    // Gunakan demo data jika dalam mode development
    if (AppConfig.isDevelopment) {
      return DemoData.getScanHistoryAsStudents();
    }

    // Gunakan Firebase untuk production
    return await FirebaseService.getScanHistoryAsStudents();
  }
}