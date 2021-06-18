import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/src/mlkit/types/barcode.dart';
import 'package:qr_code_scanner/src/mlkit/types/barcode_value_types.dart';
import 'types/barcode_formats.dart';
import 'types/preview_details.dart';

class MLKit {

  final MethodChannel _channel = MethodChannel('net.touchcapture.qr.flutterqr/mlkit');
  late MLKitController channelReader;

  //Set target size before starting
  Future<PreviewDetails> start({
    required int width,
    required int height,
    required MLKitCallback qrCodeHandler,
    List<BarcodeFormatsMLKit>? formats,
  }) async {

    channelReader = MLKitController(channel: _channel,
        qrCodeHandler: qrCodeHandler);

    formats ??= [BarcodeFormatsMLKit.ALL_FORMATS];

    final formatStrings = formats
        .map((format) => format.toString().split('.')[1])
        .toList(growable: false);

    var details = await _channel.invokeMethod('startMLKit', {
      'targetWidth': width,
      'targetHeight': height,
      'formats': formatStrings
    });

    assert(details is Map<dynamic, dynamic>);

    int textureId = details['textureId'];
    num orientation = details['surfaceOrientation'];
    num surfaceHeight = details['surfaceHeight'];
    num surfaceWidth = details['surfaceWidth'];

    return PreviewDetails(
        surfaceWidth, surfaceHeight, orientation, textureId);
  }

  Future<void> stop() {
    return _channel.invokeMethod('stopMLKit').catchError(print);
  }

  Future<dynamic> getSupportedSizes() {
    return _channel.invokeMethod('getSupportedSizes').catchError(print);
  }
}

enum FrameRotation { none, ninetyCC, oneeighty, twoseventyCC }

typedef MLKitCallback = void Function(BarcodeMLKit qr);

class MLKitController {


  void dispose() {
    _scanUpdateController.close();
  }

  MethodChannel channel;
  MLKitCallback qrCodeHandler;

  final StreamController<BarcodeMLKit> _scanUpdateController =
  StreamController<BarcodeMLKit>();

  Stream<BarcodeMLKit> get scannedDataStream => _scanUpdateController.stream;


  MLKitController({required this.channel, required this.qrCodeHandler}) {
    channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'qrRead':
          if (call.arguments != null) {
            // debugPrint('ARGUMENTS: ${call.arguments}');
            final args = call.arguments as Map;
            final valueType = args['valueType'];

            final format = intToFormat(args['format']);
            final displayValue = args['displayValue'];
            final rawValue = args['rawValue'];

            // final String boundingBox = args['boundingBox'];
            // final bounding = boundingBox.split(' ');

            final barcode = BarcodeMLKit(
                displayValue: displayValue.toString(),
                rawValue: rawValue.toString(),
                valueType: BarcodeValueTypesMLKit.values[valueType],
                format: format,
            // boundingBox: Rect.fromLTRB(double.parse(bounding[1]) / 2, double.parse(bounding[2]) / 2,(1080 - double.parse(bounding[3]) / 2), double.parse(bounding[0]) / 2)
            );

            _scanUpdateController.sink.add(barcode);
            qrCodeHandler(barcode);
          }
          break;
        default:
          print('QrChannelHandler: unknown method call received at '
              '${call.method}');
      }
    });
  }

  BarcodeFormatsMLKit intToFormat(int code) {
    if (code == 0xFFFF) return BarcodeFormatsMLKit.ALL_FORMATS;
    if (code == 0x0001) return BarcodeFormatsMLKit.CODE_128;
    if (code == 0x0002) return BarcodeFormatsMLKit.CODE_39;
    if (code == 0x0004) return BarcodeFormatsMLKit.CODE_93;
    if (code == 0x0008) return BarcodeFormatsMLKit.CODABAR;
    if (code == 0x0010) return BarcodeFormatsMLKit.DATA_MATRIX;
    if (code == 0x0020) return BarcodeFormatsMLKit.EAN_13;
    if (code == 0x0040) return BarcodeFormatsMLKit.EAN_8;
    if (code == 0x0080) return BarcodeFormatsMLKit.ITF;
    if (code == 0x0100) return BarcodeFormatsMLKit.QR_CODE;
    if (code == 0x0200) return BarcodeFormatsMLKit.UPC_A;
    if (code == 0x0400) return BarcodeFormatsMLKit.UPC_E;
    if (code == 0x0800) return BarcodeFormatsMLKit.PDF417;
    if (code == 0x1000) return BarcodeFormatsMLKit.AZTEC;
    return BarcodeFormatsMLKit.UNKNOWN;
  }



}
