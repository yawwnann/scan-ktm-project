import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import '../config/platform_config.dart';
import 'result_screen.dart';

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
      appBar: AppBar(
        title: const Text('Scan KTM'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header dengan instruksi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.qr_code_scanner, size: 60, color: Colors.white),
                const SizedBox(height: 15),
                const Text(
                  'Arahkan kamera ke barcode KTM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pastikan barcode terlihat jelas dalam frame',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Scanner area atau pesan platform tidak didukung
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue[300]!, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: PlatformConfig.enableScanner
                    ? MobileScanner(
                        controller: cameraController,
                        onDetect: _onDetect,
                      )
                    : _buildUnsupportedPlatformWidget(),
              ),
            ),
          ),

          // Tombol manual input
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showManualInputDialog();
                },
                icon: const Icon(Icons.keyboard),
                label: const Text('Input Manual NIM/Plat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
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

  // Widget untuk platform yang tidak didukung
  Widget _buildUnsupportedPlatformWidget() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.orange[600]),
            const SizedBox(height: 20),
            Text(
              'Scanner Tidak Tersedia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                PlatformConfig.unsupportedPlatformMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Tampilkan dialog dengan data demo
                _showDemoDataDialog();
              },
              icon: const Icon(Icons.info),
              label: const Text('Lihat Data Demo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
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
