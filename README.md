# QR Code Scanner

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
<img src="/.resources/android_back_camera_flash.gif" width="30%" height="30%">
</p>
</td>
<td>
<p align="center">
<img src="/.resources/android_front_camera_scan.gif" width="30%" height="30%">
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
<img src="/.resources/ios_back_camera_flash.gif" width="30%" height="30%">
</p>
</td>
<td>
<p align="center">
<img src="/.resources/ios_front_camera_scan.gif" width="30%" height="30%">
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