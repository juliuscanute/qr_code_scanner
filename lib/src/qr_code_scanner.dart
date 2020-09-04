import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef QRViewCreatedCallback = void Function(QRViewController);

enum CameraFacing { back, front }

class QRView extends StatefulWidget {
  const QRView({
    @required Key key,
    @required this.onQRViewCreated,
    this.overlay,
    this.cameraFacing = CameraFacing.back,
  })  : assert(key != null),
        assert(onQRViewCreated != null),
        super(key: key);

  final QRViewCreatedCallback onQRViewCreated;

  final ShapeBorder overlay;

  final CameraFacing cameraFacing;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
  final Completer<QRViewController> _controller = Completer<QRViewController>();

  _QrCameraSettings _settings;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _getPlatformQrView(),
        if (widget.overlay != null)
          Container(
            decoration: ShapeDecoration(
              shape: widget.overlay,
            ),
          )
        else
          Container(),
      ],
    );
  }

  @override
  void didUpdateWidget(QRView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateConfiguration(_QrCameraSettings.fromWidget(widget));
  }

  Future<void> _updateConfiguration(_QrCameraSettings settings) async {
    _settings = settings;
    final controller = await _controller.future;
    await controller._updateSettings(settings);
  }

  Widget _getPlatformQrView() {
    Widget _platformQrView;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        _platformQrView = AndroidView(
          viewType: 'net.touchcapture.qr.flutterqr/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
        );
        break;
      case TargetPlatform.iOS:
        _platformQrView = UiKitView(
          viewType: 'net.touchcapture.qr.flutterqr/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: StandardMessageCodec(),
        );
        break;
      default:
        throw UnsupportedError(
            "Trying to use the default webview implementation for $defaultTargetPlatform but there isn't a default one");
    }
    return _platformQrView;
  }

  void _onPlatformViewCreated(int id) {
    final controller = QRViewController._(id, _QrCameraSettings.fromWidget(widget));
    _controller.complete(controller);

    //start the scan by updating preview View size (size is used only on iOS)
    final RenderBox renderBox = context.findRenderObject();
    controller._startScan(renderBox.size.width, renderBox.size.height);

    if (widget.onQRViewCreated != null) {
      widget.onQRViewCreated(controller);
    }
  }
}

class _QrCameraSettings {
  _QrCameraSettings({
    this.cameraFacing,
  });

  static _QrCameraSettings fromWidget(QRView widget) {
    return _QrCameraSettings(cameraFacing: widget.cameraFacing);
  }

  final CameraFacing cameraFacing;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cameraFacing': cameraFacing.index,
    };
  }

  Map<String, dynamic> updatesMap(_QrCameraSettings newSettings) {
    if (cameraFacing == newSettings.cameraFacing) {
      return null;
    }
    return <String, dynamic>{
      'cameraFacing': newSettings.cameraFacing.index,
    };
  }
}

class QRViewController {
  QRViewController._(int id, this._settings) : _channel = MethodChannel('net.touchcapture.qr.flutterqr/qrview_$id') {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  final MethodChannel _channel;

  _QrCameraSettings _settings;

  final StreamController<String> _scanUpdateController = StreamController<String>();

  Stream<String> get scannedDataStream => _scanUpdateController.stream;

  Future<void> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onRecognizeQR':
        if (call.arguments != null) {
          _scanUpdateController.sink.add(call.arguments.toString());
        }
    }
  }

  Future<void> _startScan(double width, double height) async {
    return _channel.invokeMethod('startScan', <String, dynamic>{
      'width': width,
      'height': height,
      ..._settings.toMap(),
    });
  }

  Future<void> _updateSettings(_QrCameraSettings settings) async {
    final updateMap = _settings.updatesMap(settings);
    if (updateMap == null) {
      return;
    }
    _settings = settings;
    return _channel.invokeMethod('updateSettings', updateMap);
  }

  void flipCamera() {
    _channel.invokeMethod('flipCamera');
  }

  void toggleFlash() {
    _channel.invokeMethod('toggleFlash');
  }

  void pauseCamera() {
    _channel.invokeMethod('pauseCamera');
  }

  void resumeCamera() {
    _channel.invokeMethod('resumeCamera');
  }

  void dispose() {
    _scanUpdateController.close();
  }
}
