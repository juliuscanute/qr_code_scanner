import 'package:flutter/material.dart';
import 'package:qr_code_scanner_example/mlkit.dart';
import 'package:qr_code_scanner_example/qrview.dart';
void main() {
  runApp(QrCodeScannerExample());
}

class QrCodeScannerExample extends StatefulWidget {
  @override
  _QrCodeScannerExampleState createState() => _QrCodeScannerExampleState();
}

class _QrCodeScannerExampleState extends State<QrCodeScannerExample> {

  int _currentIndex = 0;
  final List<Widget> _children = [
    QRViewExample(),
    MLKit()
  ];

  @override
  void initState() {
    super.initState();
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('QR code scanner'),
        ),
        bottomNavigationBar: BottomNavigationBar(
          onTap: onTabTapped, // new
          currentIndex: _currentIndex, // new
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code),
              label: 'QRView',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'MLKit',
            ),
          ],
        ),
        body: _children[_currentIndex], // new
      ),
    );
  }
}


