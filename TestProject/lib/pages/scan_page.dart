// import 'dart:io'; // Needed for platform check in reassemble

// import 'package:flutter/material.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';

// class ScanPage extends StatefulWidget {
//   const ScanPage({super.key});

//   @override
//   State<ScanPage> createState() => _ScanPageState();
// }

// class _ScanPageState extends State<ScanPage> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   Barcode? result;
//   QRViewController? controller;
//   bool _isProcessing = false; // Flag to prevent multiple pops

//   // Reassemble logic for qr_code_scanner (pauses/resumes camera on hot reload)
//   @override
//   void reassemble() {
//     super.reassemble();
//     if (controller != null) {
//       // Use 'Platform' check from dart:io if needed, but Theme.of(context).platform works too
//        if (Platform.isAndroid) {
//          controller!.pauseCamera();
//        }
//        // Resume camera right away or based on state if needed
//        controller!.resumeCamera();
//        // Note: Original code had iOS resuming, Android pausing. Typically you want to resume. Adjust as needed.
//     }
//   }

//   // Called when the QRView is created
//   void _onQRViewCreated(QRViewController controller) {
//     setState(() { // Update controller state if needed, or just assign
//       this.controller = controller;
//     });
//     controller.scannedDataStream.listen((scanData) {
//       if (!_isProcessing && scanData.code != null && scanData.code!.isNotEmpty) {
//         setState(() {
//           _isProcessing = true;
//           result = scanData; // Store result if you want to display it briefly
//         });
//         print('QR Code Found: ${scanData.code}');

//         // Pause camera to prevent multiple scans immediately
//         controller.pauseCamera();

//         // Pop screen and return the scanned code string
//         if (mounted) {
//           Navigator.pop(context, scanData.code); // Return the code!
//         }
//       }
//     });
//   }

//   // Called when permission status changes
//   void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
//     print('${DateTime.now().toIso8601String()}_onPermissionSet $p');
//     if (!p) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Camera permission not granted')),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     controller?.dispose(); // Dispose the QRViewController
//     super.dispose();
//   }

//   // Builds the QRView widget
//   Widget _buildQrView(BuildContext context) {
//     // Adjust scan area size based on screen size
//     var scanArea = (MediaQuery.of(context).size.width < 400 ||
//             MediaQuery.of(context).size.height < 400)
//         ? 200.0 // Slightly larger min size
//         : 300.0;

//     return QRView(
//       key: qrKey,
//       onQRViewCreated: _onQRViewCreated,
//       overlay: QrScannerOverlayShape( // Custom overlay styling
//         borderColor: Theme.of(context).primaryColor, // Use theme color
//         borderRadius: 10,
//         borderLength: 30,
//         borderWidth: 10,
//         cutOutSize: scanArea,
//         cutOutBottomOffset: 20 // Optional: Adjust position
//       ),
//       onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p), // Handle permissions
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//        appBar: AppBar(title: const Text('Scan QR Code')), // Added AppBar
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             flex: 5, // Give scanner more space
//             child: _buildQrView(context)
//           ),
//           Expanded( // Area to display result (optional, as it pops quickly)
//             flex: 1,
//             child: Center(
//               child: (result != null)
//                   ? Text('Code Found: ${result!.code}')
//                   : const Text('Align QR Code within frame'), // Guidance text
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Step 1: Import

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  // Step 2 & 3: Use MobileScannerController and initialize
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose(); // Step 3: Dispose controller
    super.dispose();
  }

  // Step 6: Helper function for a custom overlay (example)
  Widget _buildScanOverlay(BuildContext context) {
    double scanAreaSize = (MediaQuery.of(context).size.width < 400 ||
                           MediaQuery.of(context).size.height < 400)
                          ? 250.0 // Adjusted size
                          : 300.0;
    return Center(
      child: Container(
        width: scanAreaSize,
        height: scanAreaSize,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.7),
            width: 4,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
         child: Container( // Optional inner shaded area effect
           decoration: BoxDecoration(
             color: Colors.black.withOpacity(0.3),
             borderRadius: BorderRadius.circular(8),
           ),
         ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack( // Step 6: Use Stack for layering scanner and overlay
        children: <Widget>[
          // Step 4 & 5: Use MobileScanner and onDetect
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (!_isProcessing && barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;

                if (code != null && code.isNotEmpty) {
                  setState(() { _isProcessing = true; });
                  print('QR Code Found (mobile_scanner): $code');

                  // Stop scanning before popping
                  controller.stop();

                  if (mounted) {
                    Navigator.pop(context, code); // Return the code!
                  }
                }
              }
            },
            // Optional: Handle camera errors
             errorBuilder: (context, error, child) {
               // Use a more user-friendly message if needed
               String errorMessage = 'An error occurred';
               if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
                 errorMessage = 'Camera permission denied';
               } else if (error.errorDetails != null){
                  errorMessage = error.errorDetails!.message ?? errorMessage;
               }
               return Center(
                 child: Container(
                   padding: EdgeInsets.all(16),
                   color: Colors.black.withOpacity(0.7),
                   child: Text(
                     'Scanner Error: $errorMessage',
                     style: TextStyle(color: Colors.white),
                     textAlign: TextAlign.center,
                   ),
                 ),
               );
             },
          ),
          // Step 6: Add your custom overlay widget on top
          _buildScanOverlay(context),

          // Optional: Add other UI elements like guidance text or torch toggle button
          // Positioned( ... child: Text('Align QR Code within frame') ... )
          // Positioned( top: 10, right: 10, child: IconButton(...) ) // Torch toggle example
        ],
      ),
    );
  }
}