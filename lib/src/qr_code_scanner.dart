import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'qr_scanner_overlay_shape.dart';
import 'types/barcode.dart';
import 'types/barcode_format.dart';
import 'types/camera.dart';
import 'types/camera_exception.dart';
import 'types/features.dart';

typedef QRViewCreatedCallback = void Function(QRViewController);
typedef PermissionSetCallback = void Function(QRViewController, bool);

/// The [QRView] is the view where the camera and the barcode scanner gets displayed.
class QRView extends StatefulWidget {
  const QRView({
    @required Key key,
    @required this.onQRViewCreated,
    this.overlay,
    this.overlayMargin = EdgeInsets.zero,
    this.cameraFacing = CameraFacing.back,
    this.onPermissionSet,
    this.showNativeAlertDialog = false,
  })  : assert(key != null),
        assert(onQRViewCreated != null),
        super(key: key);

  final QRViewCreatedCallback onQRViewCreated;
  final ShapeBorder overlay;
  final EdgeInsetsGeometry overlayMargin;
  final CameraFacing cameraFacing;
  final PermissionSetCallback onPermissionSet;
  final bool showNativeAlertDialog;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
  var _channel;

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
              scanArea: widget.overlay != null
                  ? (widget.overlay as QrScannerOverlayShape).cutOutSize
                  : 0.0)
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
    // We pass the cutout size so that the scanner respects the scan area.
    var cutOutSize = 0.0;
    if (widget.overlay != null) {
      cutOutSize = (widget.overlay as QrScannerOverlayShape).cutOutSize;
    }

    _channel = MethodChannel('net.touchcapture.qr.flutterqr/qrview_$id');

    // Start scan after creation of the view
    final controller = QRViewController._(_channel, widget.key, cutOutSize,
        widget.onPermissionSet, widget.showNativeAlertDialog)
      .._startScan(widget.key, cutOutSize);

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

const _formatNames = <String, BarcodeFormat>{
  'AZTEC': BarcodeFormat.aztec,
  'CODABAR': BarcodeFormat.codabar,
  'CODE_39': BarcodeFormat.code39,
  'CODE_93': BarcodeFormat.code93,
  'CODE_128': BarcodeFormat.code128,
  'DATA_MATRIX': BarcodeFormat.dataMatrix,
  'EAN_8': BarcodeFormat.ean8,
  'EAN_13': BarcodeFormat.ean13,
  'ITF': BarcodeFormat.itf,
  'MAXICODE': BarcodeFormat.maxicode,
  'PDF_417': BarcodeFormat.pdf417,
  'QR_CODE': BarcodeFormat.qrcode,
  'RSS_14': BarcodeFormat.rss14,
  'RSS_EXPANDED': BarcodeFormat.rssExpanded,
  'UPC_A': BarcodeFormat.upcA,
  'UPC_E': BarcodeFormat.upcE,
  'UPC_EAN_EXTENSION': BarcodeFormat.upcEanExtension,
};

class QRViewController {
  QRViewController._(
    MethodChannel channel,
    GlobalKey qrKey,
    double scanArea,
    PermissionSetCallback onPermissionSet,
    bool showNativeAlertDialogOnError,
  ) : _channel = channel {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onRecognizeQR':
          if (call.arguments != null) {
            final args = call.arguments as Map;
            final code = args['code'] as String;
            final rawType = args['type'] as String;
            // Raw bytes are only supported by Android.
            final rawBytes = args['rawBytes'] as List<int>;
            final format = _formatNames[rawType];
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
              if (showNativeAlertDialogOnError) {
                await showNativeAlertDialog();
              }
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
  Future<void> _startScan(
    GlobalKey key,
    double cutOutSize,
  ) async {
    // We need to update the dimension before the scan is started.
    QRViewController.updateDimensions(key, _channel, scanArea: cutOutSize);
    return _channel.invokeMethod('startScan');
  }

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

  /// Pauses barcode scanning
  Future<void> pauseCamera() async {
    try {
      await _channel.invokeMethod('pauseCamera');
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

  Future<void> showNativeAlertDialog() async {
    try {
      await _channel.invokeMethod('showNativeAlertDialog');
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> setAllowedBarcodeTypes(List<BarcodeFormat> list) async {
    try {
      await _channel.invokeMethod('setAllowedBarcodeFormats',
          list?.map((e) => e.asInt())?.toList() ?? []);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<SystemFeatures> getSystemFeatures() async {
    try {
      var features =
          await _channel.invokeMapMethod<String, dynamic>('getSystemFeatures');
      return SystemFeatures.fromJson(features);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Disposes the barcode stream.
  void dispose() {
    _scanUpdateController.close();
  }

  /// Updates the view dimensions for iOS.
  static void updateDimensions(GlobalKey key, MethodChannel channel,
      {double scanArea}) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final RenderBox renderBox = key.currentContext.findRenderObject();
      channel.invokeMethod('setDimensions', {
        'width': renderBox.size.width,
        'height': renderBox.size.height,
        'scanArea': scanArea ?? 0
      });
    }
  }
}
