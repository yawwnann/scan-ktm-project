import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';
import '../config/app_config.dart';
import '../data/demo_data.dart';
import '../utils/logger.dart';

class StudentService {
  // Fungsi untuk mendapatkan data mahasiswa berdasarkan barcode
  static Future<Student?> getStudentByBarcode(String barcode) async {
    // Gunakan demo data jika dalam mode development
    if (AppConfig.isDevelopment) {
      return DemoData.findStudentByBarcode(barcode);
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/students/$barcode'),
        headers: {
          'Content-Type': 'application/json',
          // Tambahkan header autentikasi jika diperlukan
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Student.fromJson(data);
      } else {
        Logger.error('HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      Logger.error('Exception in API call', e);
      return null;
    }
  }

  // Fungsi untuk mendapatkan data mahasiswa berdasarkan NIM
  static Future<Student?> getStudentByNIM(String nim) async {
    // Gunakan demo data jika dalam mode development
    if (AppConfig.isDevelopment) {
      return DemoData.findStudentByNIM(nim);
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/students/nim/$nim'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Student.fromJson(data);
      } else {
        Logger.error('HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      Logger.error('Exception in API call', e);
      return null;
    }
  }

  // Fungsi untuk mendapatkan data mahasiswa berdasarkan nomor plat
  static Future<Student?> getStudentByVehicleNumber(
    String vehicleNumber,
  ) async {
    // Gunakan demo data jika dalam mode development
    if (AppConfig.isDevelopment) {
      return DemoData.findStudentByVehicleNumber(vehicleNumber);
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/students/vehicle/$vehicleNumber'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Student.fromJson(data);
      } else {
        Logger.error('HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      Logger.error('Exception in API call', e);
      return null;
    }
  }

  // Fungsi untuk menyimpan riwayat scanning (opsional)
  static Future<bool> saveScanHistory(Student student) async {
    // Gunakan demo data jika dalam mode development
    if (AppConfig.isDevelopment) {
      // Untuk demo, anggap selalu berhasil
      Logger.info('Demo mode: Data scanning disimpan untuk ${student.name}');
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/scan-history'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(student.toJson()),
      );

      return response.statusCode == 201;
    } catch (e) {
      Logger.error('Exception in API call', e);
      return false;
    }
  }
}
