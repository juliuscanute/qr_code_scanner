
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class MLKit extends StatefulWidget {

  @override
  State<MLKit> createState() => _MLKitState();
}

class _MLKitState extends State<MLKit> {


  String? result;
  int nrScanned = 0;
  BarcodeValueTypesMLKit valueType = BarcodeValueTypesMLKit.UNKNOWN;
  BarcodeFormatsMLKit barcodeFormat = BarcodeFormatsMLKit.UNKNOWN;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 9,
            child: MLKitScanner(
            onError: (context, error) => Text(
              error.toString(),
              style: TextStyle(color: Colors.red),
            ),
            qrCodeCallback: (code) {
              setState(() {
                nrScanned++;
                result = code.displayValue;
                valueType = code.valueType;
                barcodeFormat = code.format;
              });
            },
        ),
          ),
          if (result != null)
            Expanded(
              flex: 1,
              child: Center(
                  child: Text(
                      '#$nrScanned Format: ${describeEnum(barcodeFormat)}, Type: ${describeEnum(valueType)}, Value: $result'
                  )
              ),
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