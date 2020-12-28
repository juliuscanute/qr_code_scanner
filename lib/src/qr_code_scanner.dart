import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

typedef QRViewCreatedCallback = void Function(QRViewController);

enum CameraFacing {
  /// Shows back facing camera.
  back,

  /// Shows front facing camera.
  front
}

enum BarcodeFormat {
  /// Aztec 2D barcode format.
  aztec,

  /// CODABAR 1D format.
  codabar,

  /// Code 39 1D format.
  code39,

  /// Code 93 1D format.
  code93,

  /// Code 128 1D format.
  code128,

  /// Data Matrix 2D barcode format.
  dataMatrix,

  /// EAN-8 1D format.
  ean8,

  /// EAN-13 1D format.
  ean13,

  /// ITF (Interleaved Two of Five) 1D format.
  itf,

  /// MaxiCode 2D barcode format.
  maxicode,

  /// PDF417 format.
  pdf417,

  /// QR Code 2D barcode format.
  qrcode,

  /// RSS 14
  rss14,

  /// RSS EXPANDED
  rssExpanded,

  /// UPC-A 1D format.
  upcA,

  /// UPC-E 1D format.
  upcE,

  /// UPC/EAN extension format. Not a stand-alone format.
  upcEanExtension
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

/// The [Barcode] object holds information about the barcode or qr code.
///
/// [code] is the content of the barcode.
/// [format] displays which type the code is.
/// Only for Android, [rawBytes] gives a list of bytes of the result.
class Barcode {
  Barcode(this.code, this.format, this.rawBytes);

  final String code;
  final BarcodeFormat format;

  /// Raw bytes are only supported by Android.
  final List<int> rawBytes;
}

/// The [QRView] is the view where the camera and the barcode scanner gets displayed.
class QRView extends StatefulWidget {
  const QRView({
    @required Key key,
    @required this.onQRViewCreated,
    this.overlay,
    this.overlayMargin = EdgeInsets.zero,
    this.cameraFacing = CameraFacing.back,
  })  : assert(key != null),
        assert(onQRViewCreated != null),
        super(key: key);

  final QRViewCreatedCallback onQRViewCreated;
  final ShapeBorder overlay;
  final EdgeInsetsGeometry overlayMargin;
  final CameraFacing cameraFacing;

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
    final controller = QRViewController._(_channel, widget.key, cutOutSize)
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

class QRViewController {
  QRViewController._(MethodChannel channel, GlobalKey qrKey, double scanArea)
      : _channel = channel {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  final MethodChannel _channel;
  final StreamController<Barcode> _scanUpdateController =
      StreamController<Barcode>();

  Stream<Barcode> get scannedDataStream => _scanUpdateController.stream;

  Future<void> _onMethodCall(MethodCall call) async {
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
    }
  }

  /// Starts the barcode scanner
  Future<void> _startScan(
    GlobalKey key,
    double cutOutSize,
  ) async {
    // We need to update the dimension before the scan is started.
    QRViewController.updateDimensions(key, _channel, scanArea: cutOutSize);
    return _channel.invokeMethod('startScan');
  }

  /// Flips the camera between available modes
  void flipCamera() {
    _channel.invokeMethod('flipCamera');
  }

  /// Toggles the flashlight between available modes
  void toggleFlash() {
    _channel.invokeMethod('toggleFlash');
  }

  /// Pauses barcode scanning
  void pauseCamera() {
    _channel.invokeMethod('pauseCamera');
  }

  /// Resumes barcode scanning
  void resumeCamera() {
    _channel.invokeMethod('resumeCamera');
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
