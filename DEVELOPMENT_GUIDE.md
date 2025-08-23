# Panduan Development - STNK Check UAD

## 🚀 Quick Start

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Run in Development Mode

```bash
# Web (untuk testing UI - scanner tidak akan berfungsi)
flutter run -d chrome

# Android Emulator/Device
flutter run

# iOS Simulator/Device (jika tersedia)
flutter run -d ios
```

### 3. Testing dengan Data Demo

Aplikasi sudah dilengkapi dengan data demo untuk testing:

**NIM untuk testing:**

- `2021001` - Ahmad Fauzi (Motor: AB 1234 CD)
- `2021002` - Siti Nurhaliza (Motor: AB 5678 EF)
- `2021003` - Budi Santoso (Mobil: AB 9012 GH)
- `2021004` - Dewi Sartika (Motor: AB 3456 IJ)
- `2021005` - Rizki Pratama (Mobil: AB 7890 KL)

**Cara Testing:**

1. Gunakan tombol "Input Manual NIM/Plat"
2. Pilih "NIM" atau "Plat"
3. Masukkan salah satu data di atas

## 🏗️ Struktur Proyek

```
lib/
├── main.dart                 # Entry point aplikasi
├── config/
│   ├── app_config.dart      # Konfigurasi aplikasi
│   └── platform_config.dart # Konfigurasi platform
├── models/
│   └── student.dart         # Model data mahasiswa
├── services/
│   └── student_service.dart # Service untuk API calls
├── data/
│   └── demo_data.dart       # Data demo untuk testing
├── screens/
│   ├── scan_screen.dart     # Halaman utama scanning
│   └── result_screen.dart   # Halaman hasil scanning
└── utils/
    └── logger.dart          # Utility untuk logging
```

## ⚙️ Konfigurasi

### Mode Development vs Production

Edit `lib/config/app_config.dart`:

```dart
// Development mode (menggunakan data demo)
static const bool isDevelopment = true;

// Production mode (menggunakan API real)
static const bool isDevelopment = false;
```

### Konfigurasi API

Untuk production, update URL API di `app_config.dart`:

```dart
static const String baseUrl = 'https://api-kampus-uad.com/api';
```

### Platform Support

- ✅ **Android**: Full support dengan camera scanning
- ✅ **iOS**: Full support dengan camera scanning
- ⚠️ **Web**: UI support saja, scanner tidak berfungsi (menampilkan data demo)

## 🔧 Build Commands

### Debug Build

```bash
# Android APK
flutter build apk --debug

# iOS (macOS only)
flutter build ios --debug
```

### Release Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle (untuk Play Store)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release
```

## 🐛 Debugging

### Logging

Aplikasi menggunakan custom logger yang bisa dilihat di:

```bash
flutter logs
```

Logger levels:

- 🐛 **DEBUG**: Detail debugging info
- ℹ️ **INFO**: Informasi umum
- ⚠️ **WARNING**: Peringatan
- ❌ **ERROR**: Error messages
- 🌐 **NETWORK**: Network requests
- 📷 **SCANNER**: Scanner activities

### Common Issues

**1. Scanner tidak berfungsi di web**

- Normal behavior, gunakan "Input Manual" untuk testing di web

**2. Camera permission denied**

- Pastikan izin kamera sudah diberikan di device settings

**3. API Error**

- Cek koneksi internet
- Pastikan URL API sudah benar di `app_config.dart`

## 📱 Testing di Device

### Android

1. Enable Developer Options di phone
2. Enable USB Debugging
3. Connect phone via USB
4. Run: `flutter run`

### iOS (macOS only)

1. Connect iPhone via USB
2. Trust computer di iPhone
3. Run: `flutter run`

## 🚀 Deployment

### Persiapan Production

1. Set `isDevelopment = false` di `app_config.dart`
2. Update API URL ke server production
3. Test dengan data real
4. Build release version

### Android Play Store

```bash
flutter build appbundle --release
```

Upload file `build/app/outputs/bundle/release/app-release.aab`

### iOS App Store (macOS only)

```bash
flutter build ios --release
```

Upload via Xcode atau Application Loader

## 🔄 API Integration

### Required Endpoints

Aplikasi membutuhkan endpoint berikut:

```
GET /api/students/{barcode}
GET /api/students/nim/{nim}
GET /api/students/vehicle/{vehicleNumber}
POST /api/scan-history
```

### Response Format

```json
{
  "nim": "2021001",
  "name": "Ahmad Fauzi",
  "faculty": "Fakultas Teknologi Industri",
  "study_program": "Teknik Informatika",
  "vehicle_number": "AB 1234 CD",
  "vehicle_type": "Motor"
}
```

## 📝 Notes

- Aplikasi ini dirancang khusus untuk mobile scanning
- Data demo sudah tersedia untuk testing tanpa API
- UI responsive untuk berbagai ukuran layar
- Support Material Design 3

## 🆘 Support

Untuk pertanyaan teknis atau bug report, silakan:

1. Check dokumentasi di README.md
2. Review kode di file terkait
3. Contact tim development UAD
