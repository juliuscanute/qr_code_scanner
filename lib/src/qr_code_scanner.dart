import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'lifecycle_event_handler.dart';
import 'qr_scanner_overlay_shape.dart';
import 'types/barcode.dart';
import 'types/barcode_format.dart';
import 'types/camera.dart';
import 'types/camera_exception.dart';
import 'types/features.dart';

typedef QRViewCreatedCallback = void Function(QRViewController);
typedef PermissionSetCallback = void Function(QRViewController, bool);

/// The [QRView] is the view where the camera
/// and the barcode scanner gets displayed.
class QRView extends StatefulWidget {
  const QRView({
    @required Key key,
    @required this.onQRViewCreated,
    this.overlay,
    this.overlayMargin = EdgeInsets.zero,
    this.cameraFacing = CameraFacing.back,
    this.onPermissionSet,
    this.formatsAllowed,
  })  : assert(key != null),
        assert(onQRViewCreated != null),
        super(key: key);

  /// [onQRViewCreated] gets called when the view is created
  final QRViewCreatedCallback onQRViewCreated;

  /// Use [overlay] to provide an overlay for the view.
  /// This can be used to create a certain scan area.
  final QrScannerOverlayShape overlay;

  /// Use [overlayMargin] to provide a margin to [overlay]
  final EdgeInsetsGeometry overlayMargin;

  /// Set which camera to use on startup.
  ///
  /// [cameraFacing] can either be CameraFacing.front or CameraFacing.back.
  /// Defaults to CameraFacing.back
  final CameraFacing cameraFacing;

  /// Calls the provided [onPermissionSet] callback when the permission is set.
  final PermissionSetCallback onPermissionSet;

  /// Use [formatsAllowed] to specify which formats needs to be scanned.
  final List<BarcodeFormat> formatsAllowed;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
  var _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(LifecycleEventHandler(
        resumeCallBack: () async => QRViewController.updateDimensions(
            widget.key, _channel,
            overlay: widget.overlay)));
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: onNotification,
      child: SizeChangedLayoutNotifier(
        child: (widget.overlay != null)
            ? _getPlatformQrViewWithOverlay()
            : _getPlatformQrView(),
      ),
    );
  }

  bool onNotification(notification) {
    Future.microtask(() => {
          QRViewController.updateDimensions(widget.key, _channel,
              overlay: widget.overlay)
        });
    return false;
  }

  Widget _getPlatformQrViewWithOverlay() {
    return Stack(
      children: [
        _getPlatformQrView(),
        Container(
          padding: widget.overlayMargin,
          decoration: ShapeDecoration(
            shape: widget.overlay,
          ),
        )
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
          creationParams:
              _QrCameraSettings(cameraFacing: widget.cameraFacing).toMap(),
          creationParamsCodec: StandardMessageCodec(),
        );
        break;
      case TargetPlatform.iOS:
        _platformQrView = UiKitView(
          viewType: 'net.touchcapture.qr.flutterqr/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParams:
              _QrCameraSettings(cameraFacing: widget.cameraFacing).toMap(),
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
    _channel = MethodChannel('net.touchcapture.qr.flutterqr/qrview_$id');

    // Start scan after creation of the view
    final controller =
        QRViewController._(_channel, widget.key, widget.onPermissionSet)
          .._startScan(widget.key, widget.overlay, widget.formatsAllowed);

    // Initialize the controller for controlling the QRView
    if (widget.onQRViewCreated != null) {
      widget.onQRViewCreated(controller);
    }
  }
}

class _QrCameraSettings {
  _QrCameraSettings({
    this.cameraFacing,
  });

  final CameraFacing cameraFacing;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cameraFacing': cameraFacing.index,
    };
  }
}

class QRViewController {
  QRViewController._(MethodChannel channel, GlobalKey qrKey,
      PermissionSetCallback onPermissionSet)
      : _channel = channel {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onRecognizeQR':
          if (call.arguments != null) {
            final args = call.arguments as Map;
            final code = args['code'] as String;
            final rawType = args['type'] as String;
            // Raw bytes are only supported by Android.
            final rawBytes = args['rawBytes'] as List<int>;
            final format = BarcodeTypesExtension.fromString(rawType);
            if (format != null) {
              final barcode = Barcode(code, format, rawBytes);
              _scanUpdateController.sink.add(barcode);
            } else {
              throw Exception('Unexpected barcode type $rawType');
            }
          }
          break;
        case 'onPermissionSet':
          await getSystemFeatures(); // if we have no permission all features will not be avaible
          if (call.arguments != null) {
            if (call.arguments as bool) {
              _hasPermissions = true;
            } else {
              _hasPermissions = false;
            }
            if (onPermissionSet != null) {
              onPermissionSet(this, call.arguments as bool);
            }
          }
          break;
      }
    });
  }

  final MethodChannel _channel;
  final StreamController<Barcode> _scanUpdateController =
      StreamController<Barcode>();

  Stream<Barcode> get scannedDataStream => _scanUpdateController.stream;

  SystemFeatures _features;
  bool _hasPermissions;

  SystemFeatures get systemFeatures => _features;
  bool get hasPermissions => _hasPermissions;

  /// Starts the barcode scanner
  Future<void> _startScan(GlobalKey key, QrScannerOverlayShape overlay,
      List<BarcodeFormat> barcodeFormats) async {
    // We need to update the dimension before the scan is started.
    try {
      await QRViewController.updateDimensions(key, _channel, overlay: overlay);
      return await _channel.invokeMethod(
          'startScan', barcodeFormats?.map((e) => e.asInt())?.toList() ?? []);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Gets information about which camera is active.
  Future<CameraFacing> getCameraInfo() async {
    try {
      return CameraFacing
          .values[await _channel.invokeMethod('getCameraInfo') as int];
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Flips the camera between available modes
  Future<CameraFacing> flipCamera() async {
    try {
      return CameraFacing
          .values[await _channel.invokeMethod('flipCamera') as int];
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Get flashlight status
  Future<bool> getFlashStatus() async {
    try {
      return await _channel.invokeMethod('getFlashInfo');
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Toggles the flashlight between available modes
  Future<void> toggleFlash() async {
    try {
      await _channel.invokeMethod('toggleFlash') as bool;
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Pauses the camera and barcode scanning
  Future<void> pauseCamera() async {
    try {
      await _channel.invokeMethod('pauseCamera');
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Stops barcode scanning and the camera
  Future<void> stopCamera() async {
    try {
      await _channel.invokeMethod('stopCamera');
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Resumes barcode scanning
  Future<void> resumeCamera() async {
    try {
      await _channel.invokeMethod('resumeCamera');
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Returns which features are available on device.
  Future<SystemFeatures> getSystemFeatures() async {
    try {
      var features =
          await _channel.invokeMapMethod<String, dynamic>('getSystemFeatures');
      return SystemFeatures.fromJson(features);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Stops the camera and disposes the barcode stream.
  void dispose() {
    stopCamera();
    _scanUpdateController.close();
  }

  /// Updates the view dimensions for iOS.
  static Future<void> updateDimensions(GlobalKey key, MethodChannel channel,
      {QrScannerOverlayShape overlay}) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final RenderBox renderBox = key.currentContext.findRenderObject();
      try {
        await channel.invokeMethod('setDimensions', {
          'width': renderBox.size.width,
          'height': renderBox.size.height,
          'scanArea': overlay?.cutOutSize ?? 0,
          'scanAreaOffset': overlay?.cutOutBottomOffset ?? 0
        });
      } on PlatformException catch (e) {
        throw CameraException(e.code, e.message);
      }
    }
  }
}
