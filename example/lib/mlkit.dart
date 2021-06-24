import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class MLKit extends StatefulWidget {
  @override
  State<MLKit> createState() => _MLKitState();
}

class _MLKitState extends State<MLKit> {
  BarcodeMLKit? barcode;
  int nrScanned = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 9,
            child: Stack(children: [
              MLKitScanner(
                onError: (context, error) => Text(
                  error.toString(),
                  style: TextStyle(color: Colors.red),
                ),
                qrCodeCallback: (BarcodeMLKit code) {
                  setState(() {
                    nrScanned++;
                    barcode = code;
                  });
                },
              ),
              // if (barcode != null)
              //   Container(
              //     width: 300,
              //     height: 300,
              //     child: CustomPaint(
              //       painter: (YourRect(barcode!.boundingBox)),
              //     ),
              //   ),
            ]),
          ),
          if (barcode != null)
            Expanded(              flex: 1,
              child: Center(
                  child: Text(
                      '#$nrScanned Format: ${describeEnum(barcode!.format)}, Type: ${describeEnum(barcode!.valueType)}, Value: ${barcode!.displayValue}')),
            )
          else
            Expanded(
              flex: 1,
              child: Center(
                child: Text('Scan a code'),
              ),
            )
        ],
      ),
    );
  }
}

// TODO: Fix scanning rectangular based on
// class YourRect extends CustomPainter {
//   final Rect barcodeRect;
//
//   YourRect(this.barcodeRect);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     canvas.drawRect(
//       barcodeRect,
//       Paint()..color = Color(0xFF0099FF),
//     );
//   }
//
//   @override
//   bool shouldRepaint(YourRect oldDelegate) {
//     return false;
//   }
// }
