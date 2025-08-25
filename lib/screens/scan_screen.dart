import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import '../config/platform_config.dart';
import 'result_screen.dart';
import 'add_edit_student_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  late MobileScannerController cameraController;
  bool isScanning = false;
  bool isNavigating = false;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  void _initializeCamera() {
    cameraController = MobileScannerController(
      autoStart: true,
      torchEnabled: false,
      useNewCameraSelector: true,
    );

    cameraController.start().then((_) {
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
      }
    }).catchError((error) {
      // ignore: avoid_print
      print('Camera initialization error: $error');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isCameraInitialized) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _pauseCamera();
        break;
      case AppLifecycleState.resumed:
        if (!isNavigating) {
          _resumeCamera();
        }
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _pauseCamera() {
    try {
      if (isCameraInitialized) {
        cameraController.stop();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error pausing camera: $e');
    }
  }

  void _resumeCamera() {
    try {
      if (mounted && !isNavigating && isCameraInitialized) {
        cameraController.start();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error resuming camera: $e');
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (isScanning || isNavigating) return;

    setState(() {
      isScanning = true;
      isNavigating = true;
    });

    // Pause camera immediately to prevent multiple scans
    _pauseCamera();

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
      // Try by barcode then by NIM
      Student? student = await StudentService.getStudentByBarcode(barcodeData);
      student ??= await StudentService.getStudentByNIM(barcodeData);

      if (student != null) {
        await StudentService.saveScanHistory(student, scanMethod: 'barcode');

        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ResultScreen(student: student!),
            ),
          );
          _resetScanningState();
        }
      } else {
        if (mounted) {
          await _promptAddData(
            title: 'Data tidak ditemukan',
            message:
                'Barcode/NIM yang di-scan tidak terdaftar dalam sistem.\nApakah Anda ingin menambahkan datanya?',
            initialBarcode: barcodeData,
            scanMethod: 'barcode',
          );
        }
        _resetScanningState();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Terjadi kesalahan: $e');
      }
      _resetScanningState();
    }
  }

  void _resetScanningState() {
    setState(() {
      isScanning = false;
      isNavigating = false;
    });

    // Resume camera after a short delay to prevent immediate re-scanning
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !isNavigating && isCameraInitialized) {
        _resumeCamera();
      }
    });
  }

  Future<void> _promptAddData({
    required String title,
    required String message,
    String? initialBarcode,
    String? scanMethod,
  }) async {
    final action = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_search,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop('add'),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Tambah Data'),
            ),
          ],
        );
      },
    );

    if (action == 'add' && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddEditStudentScreen(
            initialBarcode: initialBarcode,
            scanMethod: scanMethod,
          ),
        ),
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showManualInputDialog() {
    // Pause camera when showing manual input dialog
    if (isCameraInitialized) {
      _pauseCamera();
    }

    String inputValue = '';
    String inputType = 'NIM';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Input Manual'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                          inputValue = '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      autofocus: true,
                      keyboardType: inputType == 'NIM'
                          ? TextInputType.number
                          : TextInputType.text,
                      textCapitalization: inputType == 'NIM'
                          ? TextCapitalization.none
                          : TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: inputType == 'NIM'
                            ? 'Masukkan NIM'
                            : 'Masukkan Nomor Plat',
                        hintText: inputType == 'NIM'
                            ? 'Contoh: 2021001234'
                            : 'Contoh: AB 1234 CD',
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            inputType == 'NIM'
                                ? Icons.badge_outlined
                                : Icons.directions_car_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (value) {
                        inputValue = inputType == 'NIM'
                            ? value.trim()
                            : value.toUpperCase().trim();
                      },
                      onFieldSubmitted: (_) {
                        if (formKey.currentState!.validate()) {
                          Navigator.of(context).pop();
                          _processManualInput(inputValue, inputType);
                        }
                      },
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) {
                          return inputType == 'NIM'
                              ? 'NIM tidak boleh kosong'
                              : 'Nomor plat tidak boleh kosong';
                        }
                        if (inputType == 'NIM' && v.length != 10) {
                          return 'NIM harus 10 digit';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (isCameraInitialized && !isNavigating) {
                      _resumeCamera();
                    }
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(context).pop();
                      _processManualInput(inputValue, inputType);
                    }
                  },
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text('Cari'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (isCameraInitialized && !isNavigating) {
        _resumeCamera();
      }
    });
  }

  Future<void> _processManualInput(String inputValue, String inputType) async {
    setState(() {
      isScanning = true;
      isNavigating = true;
    });

    try {
      Student? student;

      if (inputType == 'NIM') {
        student = await StudentService.getStudentByNIM(inputValue);
      } else {
        student = await StudentService.getStudentByVehicleNumber(inputValue);
      }

      if (student != null) {
        await StudentService.saveScanHistory(student, scanMethod: 'manual');

        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ResultScreen(student: student!),
            ),
          );
          _resetScanningState();
        }
      } else {
        if (mounted) {
          await _promptAddData(
            title: 'Data tidak ditemukan',
            message:
                '${inputType == 'NIM' ? 'NIM' : 'Nomor plat'} yang diinput tidak terdaftar dalam sistem.\nApakah Anda ingin menambahkan datanya?',
            initialBarcode: inputType == 'NIM' ? inputValue : null,
            scanMethod: 'manual',
          );
        }
        _resetScanningState();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Terjadi kesalahan: $e');
      }
      _resetScanningState();
    }
  }

  // Widget untuk platform yang tidak didukung clean design
  Widget _buildUnsupportedPlatformWidget() {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scanner Tidak Tersedia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                PlatformConfig.unsupportedPlatformMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Data Demo Tersedia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: const Text(
            'Untuk testing, Anda dapat menggunakan fitur "Input Manual" dengan data berikut:\n\n'
            'NIM: 2021001, 2021002, 2021003, 2021004, 2021005\n'
            'Plat: AB 1234 CD, AB 5678 EF, AB 9012 GH, AB 3456 IJ, AB 7890 KL',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show platform warning if needed
    PlatformConfig.showPlatformWarning();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Compact Modern Header (matching OCR design)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    // Icon with modern design
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Barcode Scanner KTM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isScanning
                                ? 'Memproses scan...'
                                : !isCameraInitialized
                                    ? 'Memuat kamera...'
                                    : 'Scan barcode KTM untuk verifikasi',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status indicator
                    if (isScanning)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    else if (isCameraInitialized)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Siap',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Content area
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Scanner area with modern design
                  Container(
                    margin: const EdgeInsets.all(20),
                    height: MediaQuery.of(context).size.height * 0.45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isScanning
                            ? Colors.orange[300]!
                            : isCameraInitialized
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                : Colors.grey[200]!,
                        width: 2,
                      ),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          if (PlatformConfig.enableScanner && isCameraInitialized)
                            MobileScanner(
                              controller: cameraController,
                              onDetect: _onDetect,
                            )
                          else if (PlatformConfig.enableScanner && !isCameraInitialized)
                            _buildCameraLoadingWidget()
                          else
                            _buildUnsupportedPlatformWidget(),

                          // Processing overlay
                          if (isScanning)
                            Container(
                              color: Colors.black.withOpacity(0.4),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        children: [
                                          CircularProgressIndicator(
                                            color: Theme.of(context).colorScheme.primary,
                                            strokeWidth: 3,
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Memproses scan...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Modern Action buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        // Manual input button
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: isScanning ? null : _showManualInputDialog,
                            icon: const Icon(Icons.keyboard, size: 20),
                            label: const Text(
                              'Input Manual NIM/Plat',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Instructions card
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue[100]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tips untuk hasil terbaik:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Arahkan kamera ke barcode KTM dengan jelas\n• Pastikan barcode tidak terpotong atau buram\n• Hindari pantulan cahaya pada barcode',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for camera loading state
  Widget _buildCameraLoadingWidget() {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Memuat Kamera...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mohon tunggu sebentar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}