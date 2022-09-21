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
import 'web/flutter_qr_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) 'web/flutter_qr_web.dart';

typedef QRViewCreatedCallback = void Function(QRViewController);
typedef PermissionSetCallback = void Function(QRViewController, bool);

/// The [QRView] is the view where the camera
/// and the barcode scanner gets displayed.
class QRView extends StatefulWidget {
  const QRView({
    required Key key,
    required this.onQRViewCreated,
    this.overlay,
    this.overlayMargin = EdgeInsets.zero,
    this.cameraFacing = CameraFacing.back,
    this.onPermissionSet,
    this.formatsAllowed = const <BarcodeFormat>[],
  }) : super(key: key);

  /// [onQRViewCreated] gets called when the view is created
  final QRViewCreatedCallback onQRViewCreated;

  /// Use [overlay] to provide an overlay for the view.
  /// This can be used to create a certain scan area.
  final QrScannerOverlayShape? overlay;

  /// Use [overlayMargin] to provide a margin to [overlay]
  final EdgeInsetsGeometry overlayMargin;

  /// Set which camera to use on startup.
  ///
  /// [cameraFacing] can either be CameraFacing.front or CameraFacing.back.
  /// Defaults to CameraFacing.back
  final CameraFacing cameraFacing;

  /// Calls the provided [onPermissionSet] callback when the permission is set.
  final PermissionSetCallback? onPermissionSet;

  /// Use [formatsAllowed] to specify which formats needs to be scanned.
  final List<BarcodeFormat> formatsAllowed;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
  late MethodChannel _channel;
  late LifecycleEventHandler _observer;

  @override
  void initState() {
    super.initState();
    _observer = LifecycleEventHandler(resumeCallBack: updateDimensions);
    WidgetsBinding.instance?.addObserver(_observer);
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

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance?.removeObserver(_observer);
  }

  Future<void> updateDimensions() async {
    await QRViewController.updateDimensions(
        widget.key as GlobalKey<State<StatefulWidget>>, _channel,
        overlay: widget.overlay);
  }

  bool onNotification(notification) {
    updateDimensions();
    return false;
  }

  Widget _getPlatformQrViewWithOverlay() {
    return Stack(
      children: [
        _getPlatformQrView(),
        Padding(
          padding: widget.overlayMargin,
          child: Container(
            decoration: ShapeDecoration(
              shape: widget.overlay!,
            ),
          ),
        )
      ],
    );
  }

  Widget _getPlatformQrView() {
    Widget _platformQrView;
    if (kIsWeb) {
      _platformQrView = createWebQrView(
        onPlatformViewCreated: widget.onQRViewCreated,
        onPermissionSet: widget.onPermissionSet,
        cameraFacing: widget.cameraFacing,
      );
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          _platformQrView = AndroidView(
            viewType: 'net.touchcapture.qr.flutterqr/qrview',
            onPlatformViewCreated: _onPlatformViewCreated,
            creationParams:
                _QrCameraSettings(cameraFacing: widget.cameraFacing).toMap(),
            creationParamsCodec: const StandardMessageCodec(),
          );
          break;
        case TargetPlatform.iOS:
          _platformQrView = UiKitView(
            viewType: 'net.touchcapture.qr.flutterqr/qrview',
            onPlatformViewCreated: _onPlatformViewCreated,
            creationParams:
                _QrCameraSettings(cameraFacing: widget.cameraFacing).toMap(),
            creationParamsCodec: const StandardMessageCodec(),
          );
          break;
        default:
          throw UnsupportedError(
              "Trying to use the default qrview implementation for $defaultTargetPlatform but there isn't a default one");
      }
    }
    return _platformQrView;
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('net.touchcapture.qr.flutterqr/qrview_$id');

    // Start scan after creation of the view
    final controller = QRViewController._(
        _channel,
        widget.key as GlobalKey<State<StatefulWidget>>?,
        widget.onPermissionSet,
        widget.cameraFacing)
      .._startScan(widget.key as GlobalKey<State<StatefulWidget>>,
          widget.overlay, widget.formatsAllowed);

    // Initialize the controller for controlling the QRView
    widget.onQRViewCreated(controller);
  }
}

class _QrCameraSettings {
  _QrCameraSettings({
    this.cameraFacing = CameraFacing.unknown,
  });

  final CameraFacing cameraFacing;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cameraFacing': cameraFacing.index,
    };
  }
}

class QRViewController {
  QRViewController._(MethodChannel channel, GlobalKey? qrKey,
      PermissionSetCallback? onPermissionSet, CameraFacing cameraFacing)
      : _channel = channel,
        _cameraFacing = cameraFacing {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onRecognizeQR':
          if (call.arguments != null) {
            final args = call.arguments as Map;
            final code = args['code'] as String?;
            final rawType = args['type'] as String;
            // Raw bytes are only supported by Android.
            final rawBytes = args['rawBytes'] as List<int>?;
            final format = BarcodeTypesExtension.fromString(rawType);
            if (format != BarcodeFormat.unknown) {
              final barcode = Barcode(code, format, rawBytes);
              _scanUpdateController.sink.add(barcode);
            } else {
              throw Exception('Unexpected barcode type $rawType');
            }
          }
          break;
        case 'onPermissionSet':
          if (call.arguments != null && call.arguments is bool) {
            _hasPermissions = call.arguments;
            if (onPermissionSet != null) {
              onPermissionSet(this, _hasPermissions);
            }
          }
          break;
      }
    });
  }

  final MethodChannel _channel;
  final CameraFacing _cameraFacing;
  final StreamController<Barcode> _scanUpdateController =
      StreamController<Barcode>();

  Stream<Barcode> get scannedDataStream => _scanUpdateController.stream;

  bool _hasPermissions = false;
  bool get hasPermissions => _hasPermissions;

  /// Starts the barcode scanner
  Future<void> _startScan(GlobalKey key, QrScannerOverlayShape? overlay,
      List<BarcodeFormat>? barcodeFormats) async {
    // We need to update the dimension before the scan is started.
    try {
      await QRViewController.updateDimensions(key, _channel, overlay: overlay);
      return await _channel.invokeMethod(
          'startScan', barcodeFormats?.map((e) => e.asInt()).toList() ?? []);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Gets information about which camera is active.
  Future<CameraFacing> getCameraInfo() async {
    try {
      var cameraFacing = await _channel.invokeMethod('getCameraInfo') as int;
      if (cameraFacing == -1) return _cameraFacing;
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
  Future<bool?> getFlashStatus() async {
    try {
      return await _channel.invokeMethod('getFlashInfo');
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Toggles the flashlight between available modes
  Future<void> toggleFlash() async {
    try {
      await _channel.invokeMethod('toggleFlash') as bool?;
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
      if (features != null) {
        return SystemFeatures.fromJson(features);
      }
      throw CameraException('Error', 'Could not get system features');
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Stops the camera and disposes the barcode stream.
  void dispose() {
    if (defaultTargetPlatform == TargetPlatform.iOS) stopCamera();
    _scanUpdateController.close();
  }

  /// Updates the view dimensions for iOS.
  static Future<bool> updateDimensions(GlobalKey key, MethodChannel channel,
      {QrScannerOverlayShape? overlay}) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Add small delay to ensure the render box is loaded
      await Future.delayed(const Duration(milliseconds: 300));
      if (key.currentContext == null) return false;
      final renderBox = key.currentContext!.findRenderObject() as RenderBox;
      try {
        await channel.invokeMethod('setDimensions', {
          'width': renderBox.size.width,
          'height': renderBox.size.height,
          'scanAreaWidth': overlay?.cutOutWidth ?? 0,
          'scanAreaHeight': overlay?.cutOutHeight ?? 0,
          'scanAreaOffset': overlay?.cutOutBottomOffset ?? 0
        });
        return true;
      } on PlatformException catch (e) {
        throw CameraException(e.code, e.message);
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      if (overlay == null) {
        return false;
      }
      await channel.invokeMethod('changeScanArea', {
        'scanAreaWidth': overlay.cutOutWidth,
        'scanAreaHeight': overlay.cutOutHeight,
        'cutOutBottomOffset': overlay.cutOutBottomOffset
      });
      return true;
    }
    return false;
  }

  //Starts/Stops invert scanning.
  Future<void> scanInvert(bool isScanInvert) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel
            .invokeMethod('invertScan', {"isInvertScan": isScanInvert});
      } on PlatformException catch (e) {
        throw CameraException(e.code, e.message);
      }
    }
  }
}
