import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  // ในกรณี Hot Reload อาจจะมีการ Disposed Controller ไปแล้ว
  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        controller!.pauseCamera();
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        controller!.resumeCamera();
      }
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        // เมื่อสแกน QR Code สำเร็จ คุณสามารถทำอะไรกับข้อมูลที่ได้ได้ที่นี่
        print('QR Code Data: ${result!.code}');
        // ตัวอย่าง: นำทางไปยังหน้าอื่นพร้อมส่งข้อมูล
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => ResultPage(data: result!.code)),
        // );
      });
    });
  }

  void _onPermissionSet(QRViewController? controller, bool? isPermissionGranted) {
    print('${DateTime.now().toIso8601String()}_permission $isPermissionGranted');
    if (isPermissionGranted == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission not granted')),
      );
      // คุณอาจต้องการแสดง UI ที่แตกต่างกันที่นี่เมื่อไม่ได้รับอนุญาต
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.red,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: _onPermissionSet,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null)
                  ? Text('Data: ${result!.code}')
                  : const Text('Scan a code'),
            ),
          )
        ],
      ),
    );
  }
}