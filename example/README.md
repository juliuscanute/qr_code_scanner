# qr_code_scanner

Demonstrates how to use the qr_code_scanner plugin.
##iOS Support:

###info.plist
```xml
<dict>
    <key>io.flutter.embedded_views_preview</key>
	<true/>
	<key>UIBackgroundModes</key>
	<array>
		<string>fetch</string>
		<string>remote-notification</string>
	</array>
	<key>NSCameraUsageDescription</key>
    <string>Can we access your camera in order to scan barcodes?</string>
</dict>

```

##Example:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() => runApp(MaterialApp(home: QRViewExample()));

class QRViewExample extends StatefulWidget {
  const QRViewExample({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  var qrText = "";
  QRViewController controller;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
            flex: 4,
          ),
          Expanded(
            child: Column(children:
              <Widget>[
                Text("This is the result of scan: $qrText"),
                RaisedButton(
                  onPressed: (){
                    if(controller != null){
                      controller.flipCamera();
                    }
                  },
                  child: Text(
                      'Flip',
                      style: TextStyle(fontSize: 20)
                  ),
                )
              ],
            ),
            flex: 1,
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    final channel = controller.channel;
    controller.init(qrKey);
    this.controller = controller;
    channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case "onRecognizeQR":
          dynamic arguments = call.arguments;
          setState(() {
            qrText = arguments.toString();
          });
      }
    });
  }
}
```



