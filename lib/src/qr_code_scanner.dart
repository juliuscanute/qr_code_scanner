import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

typedef QRViewCreatedCallback = void Function(QRViewController);

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

class Barcode {
  Barcode(this.code, this.format, this.rawBytes);

  final String code;
  final BarcodeFormat format;

  /// Raw bytes are only supported by Android.
  final List<int> rawBytes;
}

class QRView extends StatefulWidget {
  const QRView({
    @required Key key,
    @required this.onQRViewCreated,
    this.overlay,
    this.overlayMargin = EdgeInsets.zero,
  })  : assert(key != null),
        assert(onQRViewCreated != null),
        super(key: key);

  final QRViewCreatedCallback onQRViewCreated;

  final ShapeBorder overlay;
  final EdgeInsetsGeometry overlayMargin;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _getPlatformQrView(widget.key),
        if (widget.overlay != null)
          Container(
            padding: widget.overlayMargin,
            decoration: ShapeDecoration(
              shape: widget.overlay,
            ),
          )
        else
          Container(),
      ],
    );
  }

  Widget _getPlatformQrView(GlobalKey key) {
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
          creationParams:
              _CreationParams.fromWidget(MediaQuery.of(context).size.width, 400)
                  .toMap(),
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

    // We pass the cutout size so that the scanner respects the scan area.
    var cutOutSize = 0.0;
    if (widget.overlay != null) {
      cutOutSize = (widget.overlay as QrScannerOverlayShape).cutOutSize;
    }

    widget.onQRViewCreated(QRViewController._(id, widget.key, cutOutSize));
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
  QRViewController._(int id, GlobalKey qrKey, double scanArea)
      : _channel = MethodChannel('net.touchcapture.qr.flutterqr/qrview_$id') {
    updateDimensions(qrKey, scanArea: scanArea);
    _channel.setMethodCallHandler(
      (call) async {
        switch (call.method) {
          case scanMethodCall:
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
      },
    );
  }

  static const scanMethodCall = 'onRecognizeQR';

  final MethodChannel _channel;

  final StreamController<Barcode> _scanUpdateController =
      StreamController<Barcode>();

  Stream<Barcode> get scannedDataStream => _scanUpdateController.stream;

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

  void updateDimensions(GlobalKey key, {double scanArea}) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final RenderBox renderBox = key.currentContext.findRenderObject();
      _channel.invokeMethod('setDimensions', {
        'width': renderBox.size.width,
        'height': renderBox.size.height,
        'scanArea': scanArea ?? 0
      });
    }
  }
}
