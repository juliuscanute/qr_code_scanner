# QR Code Scanner
[![Build Status](https://dev.azure.com/juliuscanute/spring/_apis/build/status/juliuscanute.qr_code_scanner?branchName=master)](https://dev.azure.com/juliuscanute/spring/_build/latest?definitionId=7&branchName=master)

A QR code scanner that works on both iOS and Android by natively embedding the platform view within Flutter. The integration with Flutter is seamless, much better than jumping into a native Activity or a ViewController to perform the scan.


## Screenshots
<table>
<tr>
<th colspan="2">
Android
</th>
</tr>

<tr>
<td>
<p align="center">
<img src="https://github.com/juliuscanute/qr_code_scanner/blob/master/.resources/android_back_camera_flash.gif" width="30%" height="30%">
</p>
</td>
<td>
<p align="center">
<img src="https://github.com/juliuscanute/qr_code_scanner/blob/master/.resources/android_front_camera_scan.gif" width="30%" height="30%">
</p>
</td>
</tr>

<tr>
<th colspan="2">
iOS
</th>
</tr>

<tr>
<td>
<p align="center">
<img src="https://github.com/juliuscanute/qr_code_scanner/blob/master/.resources/ios_back_camera_flash.gif" width="30%" height="30%">
</p>
</td>
<td>
<p align="center">
<img src="https://github.com/juliuscanute/qr_code_scanner/blob/master/.resources/ios_front_camera_scan.gif" width="30%" height="30%">
</p>
</td>
</tr>

</table>

## Get Scanned QR Code

When a QR code is recognized, the text identified will be set in 'qrText'.

```dart
class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  var qrText = "";
  QRViewController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
                children: <Widget>[
                    QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                    ),          
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

## iOS Integration
In order to use this plugin, add the following to your Info.plist file:
```
<key>io.flutter.embedded_views_preview</key>
<true/>
```

## Flip Camera (Back/Front)
The default camera is the back camera.
```dart
controller.flipCamera();
```

## Flash (Off/On)
By default, flash is OFF.
```dart
controller.flipFlash();
```

# TODO'S:
* iOS Native embedding is written to match what is supported in the framework as of the date of publication of this package. It needs to be improved as the framework support improves.
* In future, options will be provided for default states.
* Finally, I welcome PR's to make it better :), thanks

# Credits
* Android: https://github.com/zxing/zxing
* iOS: https://github.com/mikebuss/MTBBarcodeScanner
* Special Thanks To: LeonDevLifeLog for his contributions towards improving this package.