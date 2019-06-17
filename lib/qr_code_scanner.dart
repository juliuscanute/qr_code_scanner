import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef void QRViewCreatedCallback(QRViewController controller);

class QRView extends StatefulWidget {
  const QRView({
    Key key,
    this.onQRViewCreated,
  }) : super(key: key);

  final QRViewCreatedCallback onQRViewCreated;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
  @override
  Widget build(BuildContext context) {
    var androidView = AndroidView(
      viewType: 'net.touchcapture.qr.flutterqr/qrview',
      onPlatformViewCreated: _onPlatformViewCreated,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      return androidView;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'net.touchcapture.qr.flutterqr/qrview',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: _CreationParams.fromWidget(0, 0).toMap(),
        creationParamsCodec: StandardMessageCodec(),
      );
    }

    return Text(
        '$defaultTargetPlatform is not yet supported by the text_view plugin');
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onQRViewCreated == null) {
      return;
    }
    widget.onQRViewCreated(new QRViewController._(id));
  }
}

class _CreationParams {
  _CreationParams({this.width, this.height});

  static _CreationParams fromWidget(double width, double height) {
    return _CreationParams(
      width: width,
      height: height,
    );
  }

  final double width;
  final double height;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'width': width,
      'height': height,
    };
  }
}

class QRViewController {
  QRViewController._(int id)
      : channel = MethodChannel('net.touchcapture.qr.flutterqr/qrview_$id');
  final MethodChannel channel;

  void init(GlobalKey qrKey) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final RenderBox renderBox = qrKey.currentContext.findRenderObject();
      channel.invokeMethod("setDimensions",
          {"width": renderBox.size.width, "height": renderBox.size.height});
    }
  }

  void flipCamera(){
    channel.invokeMethod("flipCamera");
  }

  void flipFlash(){
    channel.invokeMethod("flipFlash");
  }

}
