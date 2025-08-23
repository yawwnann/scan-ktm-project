class AppConfig {
  // Base URL untuk API kampus
  static const String baseUrl = 'https://api-kampus-uad.com/api';
  
  // Timeout untuk HTTP requests (dalam detik)
  static const int httpTimeout = 30;
  
  // Nama aplikasi
  static const String appName = 'STNK Check UAD';
  
  // Versi aplikasi
  static const String appVersion = '1.0.0';
  
  // Konfigurasi untuk development
  static const bool isDevelopment = true;
  
  // Log level
  static const String logLevel = 'INFO';
  
  // Konfigurasi scanner
  static const bool enableAutoFocus = true;
  static const bool enableFlash = false;
  
  // Konfigurasi UI
  static const double defaultPadding = 20.0;
  static const double defaultRadius = 20.0;
  
  // Warna tema
  static const int primaryColor = 0xFF1976D2; // Blue
  static const int accentColor = 0xFFFF9800;  // Orange
  static const int successColor = 0xFF4CAF50; // Green
  static const int errorColor = 0xFFF44336;   // Red
  
  // Endpoints API
  static const String studentsEndpoint = '/students';
  static const String scanHistoryEndpoint = '/scan-history';
  
  // Format tanggal
  static const String dateFormat = 'dd/MM/yyyy HH:mm';
  
  // Pesan error
  static const String networkErrorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
  static const String dataNotFoundMessage = 'Data tidak ditemukan dalam sistem.';
  static const String generalErrorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
  
  // Pesan sukses
  static const String scanSuccessMessage = 'Data berhasil ditemukan!';
  static const String saveSuccessMessage = 'Data berhasil disimpan!';
}
