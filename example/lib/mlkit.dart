
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/src/mlkit/mlkit_scanner.dart';

class MLKit extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MLKitScanner(
      onError: (context, error) => Text(
        error.toString(),
        style: TextStyle(color: Colors.red),
      ),
      qrCodeCallback: (code) {
        debugPrint('Code $code');
      },
    );
  }
}