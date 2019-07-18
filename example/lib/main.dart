import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() => runApp(MaterialApp(home: QRViewExample()));

const flash_on = "FLASH ON";
const flash_off = "FLASH OFF";
const front_camera = "FRONT CAMERA";
const back_camera = "BACK CAMERA";

class QRViewExample extends StatefulWidget {
  const QRViewExample({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  var qrText = "";
  var flashState = flash_on;
  var cameraState = front_camera;
  QRViewController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: QRView(
              onQRViewCreated: _onQRViewCreated,
            ),
            flex: 4,
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                Text("This is the result of scan: $qrText"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.all(8.0),
                      child: RaisedButton(
                        onPressed: () {
                          if (controller != null) {
                            controller.toggleFlash();
                            if (_isFlashOn(flashState))
                              setState(() {
                                flashState = flash_off;
                              });
                            else
                              setState(() {
                                flashState = flash_on;
                              });
                          }
                        },
                        child: Text(flashState, style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(8.0),
                      child: RaisedButton(
                        onPressed: () {
                          if (controller != null) {
                            controller.flipCamera();
                            if (_isBackCamera(cameraState))
                              setState(() {
                                cameraState = front_camera;
                              });
                            else
                              setState(() {
                                cameraState = back_camera;
                              });
                          }
                        },
                        child:
                            Text(cameraState, style: TextStyle(fontSize: 20)),
                      ),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(bottom: 8.0),
                      child: RaisedButton(
                        onPressed: () {
                          controller?.pauseCamera();
                        },
                        child: Text('pause', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(bottom: 8.0),
                      child: RaisedButton(
                        onPressed: () {
                          controller.resumeCamera();
                        },
                        child: Text('resume', style: TextStyle(fontSize: 20)),
                      ),
                    )
                  ],
                ),
              ],
            ),
            flex: 1,
          )
        ],
      ),
    );
  }

  _isFlashOn(String current) {
    return flash_on == current;
  }

  _isBackCamera(String current) {
    return back_camera == current;
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedData.listen((scanData) {
      setState(() {
        qrText = scanData;
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
