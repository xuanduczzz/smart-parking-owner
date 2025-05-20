import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart' as qr;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/qr/qr_bloc.dart';
import '../blocs/qr/qr_event.dart';
import '../blocs/qr/qr_state.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  qr.QRViewController? controller;
  String? result;
  final ImagePicker _picker = ImagePicker();
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  Future<void> _scanImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final inputImage = InputImage.fromFilePath(image.path);
        final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);
        
        if (barcodes.isNotEmpty) {
          _processQRCode(barcodes.first.rawValue ?? '');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy mã QR trong ảnh'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _processQRCode(String code) {
    controller?.pauseCamera();
    context.read<QRBloc>().add(QRScanned(code));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _scanImageFromGallery,
            tooltip: 'Chọn ảnh từ thư viện',
          ),
        ],
      ),
      body: BlocListener<QRBloc, QRState>(
        listener: (context, state) {
          if (state is QRSuccess) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  'Thông báo',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                content: Text(
                  state.message,
                  style: GoogleFonts.montserrat(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'OK',
                      style: GoogleFonts.montserrat(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).then((_) {
              Navigator.of(context).pop();
            });
          } else if (state is QRError) {
            controller?.resumeCamera();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: qr.QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: qr.QrScannerOverlayShape(
                  borderColor: Colors.blue,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: MediaQuery.of(context).size.width * 0.8,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: BlocBuilder<QRBloc, QRState>(
                  builder: (context, state) {
                    if (state is QRLoading) {
                      return const CircularProgressIndicator();
                    }
                    return const Text(
                      'Quét mã QR để cập nhật trạng thái',
                      style: TextStyle(fontSize: 16),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(qr.QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        _processQRCode(scanData.code!);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }
} 