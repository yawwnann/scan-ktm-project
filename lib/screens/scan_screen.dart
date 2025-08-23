import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import '../config/platform_config.dart';
import 'result_screen.dart';
import 'student_list_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (isScanning) return;

    setState(() {
      isScanning = true;
    });

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _processBarcode(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processBarcode(String barcodeData) async {
    try {
      // Tampilkan loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Coba dapatkan data mahasiswa dari barcode
      Student? student = await StudentService.getStudentByBarcode(barcodeData);

      // Jika tidak ada, coba dari NIM
      student ??= await StudentService.getStudentByNIM(barcodeData);

      // Tutup loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (student != null) {
        // Simpan riwayat scanning
        await StudentService.saveScanHistory(student);

        // Navigasi ke halaman hasil
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ResultScreen(student: student!),
            ),
          );
        }
      } else {
        // Tampilkan error jika data tidak ditemukan
        if (mounted) {
          _showErrorDialog(
            'Data tidak ditemukan',
            'Barcode/NIM yang di-scan tidak terdaftar dalam sistem.',
          );
        }
      }
    } catch (e) {
      // Tutup loading
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog('Error', 'Terjadi kesalahan: $e');
      }
    } finally {
      setState(() {
        isScanning = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan warning platform jika diperlukan
    PlatformConfig.showPlatformWarning();

    return Scaffold(
      body: Column(
        children: [
          // Header clean modern
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B35),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Scanner KTM UAD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Arahkan kamera ke barcode KTM untuk verifikasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scanner area clean design
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF6B35), width: 2),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: PlatformConfig.enableScanner
                    ? MobileScanner(
                        controller: cameraController,
                        onDetect: _onDetect,
                      )
                    : _buildUnsupportedPlatformWidget(),
              ),
            ),
          ),

          // Tombol manual input clean
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showManualInputDialog();
                },
                icon: const Icon(Icons.keyboard, size: 20),
                label: const Text('Input Manual NIM/Plat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    String inputValue = '';
    String inputType = 'NIM'; // atau 'Plat'

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Input Manual'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pilihan input menggunakan SegmentedButton
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(value: 'NIM', label: Text('NIM')),
                      ButtonSegment<String>(
                        value: 'Plat',
                        label: Text('Nomor Plat'),
                      ),
                    ],
                    selected: {inputType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        inputType = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      labelText: inputType == 'NIM'
                          ? 'Masukkan NIM'
                          : 'Masukkan Nomor Plat',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      inputValue = value;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (inputValue.isNotEmpty) {
                      Navigator.of(context).pop();
                      _processManualInput(inputValue, inputType);
                    }
                  },
                  child: const Text('Cari'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processManualInput(String inputValue, String inputType) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      Student? student;

      if (inputType == 'NIM') {
        student = await StudentService.getStudentByNIM(inputValue);
      } else {
        student = await StudentService.getStudentByVehicleNumber(inputValue);
      }

      if (mounted) {
        Navigator.of(context).pop(); // Tutup loading
      }

      if (student != null) {
        await StudentService.saveScanHistory(student);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ResultScreen(student: student!),
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog(
            'Data tidak ditemukan',
            '$inputType yang diinput tidak terdaftar dalam sistem.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog('Error', 'Terjadi kesalahan: $e');
      }
    }
  }

  // Widget untuk platform yang tidak didukung clean design
  Widget _buildUnsupportedPlatformWidget() {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 64,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Scanner Tidak Tersedia',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                PlatformConfig.unsupportedPlatformMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  _showDemoDataDialog();
                },
                icon: const Icon(Icons.info_outline, size: 20),
                label: const Text('Lihat Data Demo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog untuk menampilkan data demo
  void _showDemoDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Data Demo Tersedia'),
          content: const Text(
            'Untuk testing, Anda dapat menggunakan fitur "Input Manual" dengan data berikut:\n\n'
            'NIM: 2021001, 2021002, 2021003, 2021004, 2021005\n'
            'Plat: AB 1234 CD, AB 5678 EF, AB 9012 GH, AB 3456 IJ, AB 7890 KL',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
