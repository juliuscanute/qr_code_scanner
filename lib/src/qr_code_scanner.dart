import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

typedef QRViewCreatedCallback = void Function(QRViewController);
typedef PermissionSetCallback = void Function(QRViewController, bool);

class QRView extends StatefulWidget {
  const QRView({
    @required Key key,
    @required this.onQRViewCreated,
    this.onPermissionSet,
    this.turnFlashOffOnDispose = true,
    this.showNativeAlertDialog = false,
    this.overlay,
  })
      : assert(key != null),
        assert(onQRViewCreated != null),
        assert(showNativeAlertDialog != null),
        assert(turnFlashOffOnDispose != null),
        super(key: key);

  final QRViewCreatedCallback onQRViewCreated;
  final PermissionSetCallback onPermissionSet;
  final bool turnFlashOffOnDispose;
  final bool showNativeAlertDialog;
  final ShapeBorder overlay;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
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
          creationParams: _CreationParams.fromWidget(0, 0).toMap(),
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
    if (widget.onQRViewCreated == null) {
      return;
    }
    widget.onQRViewCreated(QRViewController._(
        id,
        widget.key,
        widget.onPermissionSet,
        widget.showNativeAlertDialog,
        widget.turnFlashOffOnDispose));
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

enum Camera {
  BackCamera,
  FrontCamera,
}

enum ReturnStatus { Success, Failed }

extension ReturnStatusExtension on ReturnStatus {
  bool asBool() {
    return this == ReturnStatus.Success;
  }
}

class SystemFeatures {
  SystemFeatures(this.hasFlash, this.hasBackCamera, this.hasFrontCamera);

  factory SystemFeatures.fromJson(Map<String, dynamic> features) =>
      SystemFeatures(
          features['hasFlash'] ?? false,
          features['hasBackCamera'] ?? false,
          features['hasFrontCamera'] ?? false);

  final bool hasFlash;
  final bool hasFrontCamera;
  final bool hasBackCamera;
}

class QRViewController {
  QRViewController._(int id,
      GlobalKey qrKey,
      PermissionSetCallback onPermissionSet,
      bool showNativeAlertDialogOnError,
      this._turnFlashOffOnDispose,)
      : _channel = MethodChannel('net.touchcapture.qr.flutterqr/qrview_$id') {
    _channel.setMethodCallHandler(
          (call) async {
        switch (call.method) {
          case scanMethodCall:
            if (call.arguments != null) {
              _scanUpdateController.sink.add(call.arguments.toString());
            }
          break;
          case permissionMethodCall:
            await getSystemFeatures(); // if we have no permission all features will not be avaible
            print(call.arguments.toString());
            print(onPermissionSet);
            if (call.arguments != null && onPermissionSet != null) {
              if (call.arguments as bool) {
                _cameraActive = true;
              }
              if (showNativeAlertDialogOnError) {
                showNativeAlertDialog();
              }
              onPermissionSet(this, call.arguments as bool);
            }
          break;
        }
      },
    );
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final RenderBox renderBox = qrKey.currentContext.findRenderObject();
      _channel.invokeMethod('setDimensions',
          {'width': renderBox.size.width, 'height': renderBox.size.height});
    }
  }

  final bool _turnFlashOffOnDispose;
  static const scanMethodCall = 'onRecognizeQR';
  static const permissionMethodCall = 'onPermissionSet';

  final MethodChannel _channel;

  final StreamController<String> _scanUpdateController =
  StreamController<String>();

  Stream<String> get scannedDataStream => _scanUpdateController.stream;

  bool _flashActive = false;

  bool _cameraActive = false;

  int _activeCamera = 0;

  SystemFeatures _features;

  SystemFeatures get systemFeatures => _features;

  bool get cameraActive => _cameraActive;

  bool get flashActive => _flashActive;

  Camera get activeCamera =>
      _activeCamera == null ? null : Camera.values[_activeCamera];

  Future<ReturnStatus> flipCamera() async {
    try {
      _activeCamera = await _channel.invokeMethod('flipCamera') as int;
      return ReturnStatus.Success;
    } on PlatformException catch (e) {
      return ReturnStatus.Failed;
    }
  }

  Future<ReturnStatus> toggleFlash() async {
    try {
      _flashActive = await _channel.invokeMethod('toggleFlash') as bool;
      return ReturnStatus.Success;
    } on PlatformException catch (e) {
      return ReturnStatus.Failed;
    }
  }

  Future<ReturnStatus> pauseCamera() async {
    try {
      var cameraPaused = await _channel.invokeMethod('pauseCamera') as bool;
      _cameraActive = !cameraPaused;
      return ReturnStatus.Success;
    } on PlatformException catch (e) {
      return ReturnStatus.Failed;
    }
  }

  Future<ReturnStatus> resumeCamera() async {
    try {
      _cameraActive = await _channel.invokeMethod('resumeCamera');
      return ReturnStatus.Success;
    } on PlatformException catch (e) {
      return ReturnStatus.Failed;
    }
  }

  Future<ReturnStatus> showNativeAlertDialog() async {
    try {
      await _channel.invokeMethod('showNativeAlertDialog');
      return ReturnStatus.Success;
    } on PlatformException catch (e) {
      return ReturnStatus.Failed;
    }
  }

  Future<SystemFeatures> getSystemFeatures() async {
    try {
      var features = await _channel.invokeMapMethod<String, dynamic>('getSystemFeatures');
      _features = SystemFeatures.fromJson(features);
      _activeCamera = features['activeCamera'];
      return _features;
    } on PlatformException catch (e) {
      return null;
    }
  }

  void dispose() {
    if (_features.hasFlash && _turnFlashOffOnDispose && _flashActive) {
      _channel.invokeMethod('toggleFlash');
    }
    _scanUpdateController.close();
  }
}
