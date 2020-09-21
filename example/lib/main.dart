import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() => runApp(MaterialApp(home: QRViewExample()));

const flashOn = 'FLASH ON';
const flashOff = 'FLASH OFF';
const frontCamera = 'FRONT CAMERA';
const backCamera = 'BACK CAMERA';

class QRViewExample extends StatefulWidget {
  const QRViewExample({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  var qrText = '';
  var flashState = flashOn;
  var cameraState = frontCamera;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Container(
              child: Stack(
                children: [
                  QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: Colors.red,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 300,
                    ),
                  ),
                  Positioned(
                    top: barcodeData?.minY ?? 0,
                    left: barcodeData?.minX ?? 0,
                    child: Container(
                      height: barcodeData?.height ?? 0,
                      width: barcodeData?.width ?? 0,
                      color: Colors.red,
                      child: Text('${barcodeData?.code}'),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text('This is the result of scan: $qrText'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.all(8),
                        child: RaisedButton(
                          onPressed: () {
                            if (controller != null) {
                              controller.toggleFlash();
                              if (_isFlashOn(flashState)) {
                                setState(() {
                                  flashState = flashOff;
                                });
                              } else {
                                setState(() {
                                  flashState = flashOn;
                                });
                              }
                            }
                          },
                          child:
                              Text(flashState, style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(8),
                        child: RaisedButton(
                          onPressed: () {
                            if (controller != null) {
                              controller.flipCamera();
                              if (_isBackCamera(cameraState)) {
                                setState(() {
                                  cameraState = frontCamera;
                                });
                              } else {
                                setState(() {
                                  cameraState = backCamera;
                                });
                              }
                            }
                          },
                          child:
                              Text(cameraState, style: TextStyle(fontSize: 20)),
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.all(8),
                        child: RaisedButton(
                          onPressed: () {
                            controller?.pauseCamera();
                          },
                          child: Text('pause', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(8),
                        child: RaisedButton(
                          onPressed: () {
                            controller?.resumeCamera();
                          },
                          child: Text('resume', style: TextStyle(fontSize: 20)),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  bool _isFlashOn(String current) {
    return flashOn == current;
  }

  bool _isBackCamera(String current) {
    return backCamera == current;
  }

  BarcodeData barcodeData;

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      print('SonLT $scanData');
      setState(() {
        barcodeData = null;
        qrText = '';
      });
      if (scanData is List) {
        // print('ScanData $scanData');
        final first = scanData.first;
        // print('First $first');
        if (first != null) {
          setState(() {
            barcodeData =
                BarcodeData.fromJson(Map<String, dynamic>.from(first));
            qrText = barcodeData.code;
          });
        } else {
          setState(() {
            barcodeData = null;
            qrText = '';
          });
        }
      } else {
        setState(() {
          barcodeData = null;
          qrText = '';
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class BarcodeData {
  BarcodeData({
    this.height,
    this.width,
    this.minX,
    this.code,
    this.midX,
    this.minY,
    this.midY,
    this.maxY,
    this.maxX,
  });

  double height;
  double width;
  double minX;
  String code;
  double midX;
  double minY;
  double midY;
  double maxY;
  double maxX;

  factory BarcodeData.fromJson(Map<String, dynamic> json) => BarcodeData(
        height: json["height"].toDouble(),
        width: json["width"].toDouble(),
        minX: json["minX"].toDouble(),
        code: json["code"],
        midX: json["midX"].toDouble(),
        minY: json["minY"].toDouble(),
        midY: json["midY"].toDouble(),
        maxY: json["maxY"].toDouble(),
        maxX: json["maxX"].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "height": height,
        "width": width,
        "minX": minX,
        "code": code,
        "midX": midX,
        "minY": minY,
        "midY": midY,
        "maxY": maxY,
        "maxX": maxX,
      };
}
