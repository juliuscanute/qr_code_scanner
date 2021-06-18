import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:qr_code_scanner/src/mlkit/types/barcode.dart';
import 'package:qr_code_scanner/src/mlkit/types/barcode_formats.dart';

import 'mlkit.dart';
import 'types/preview_details.dart';

final WidgetBuilder _defaultNotStartedBuilder = (context) => Text('Camera Loading ...');
final WidgetBuilder _defaultOffscreenBuilder = (context) => Text('Camera Paused.');

final ErrorCallback _defaultOnError = (BuildContext context, Object error) {
  print('Error reading from camera: $error');
  return Text('Error reading from camera...');
};

typedef ErrorCallback = Widget Function(BuildContext context, Object error);

class MLKitScanner extends StatefulWidget {
  MLKitScanner({
    Key? key,
    required this.qrCodeCallback,
    this.child,
    this.fit = BoxFit.cover,
    WidgetBuilder? notStartedBuilder,
    WidgetBuilder? offscreenBuilder,
    ErrorCallback? onError,
    this.formats,
  })  : notStartedBuilder = notStartedBuilder ?? _defaultNotStartedBuilder,
        offscreenBuilder = offscreenBuilder ?? notStartedBuilder ?? _defaultOffscreenBuilder,
        onError = onError ?? _defaultOnError,
        super(key: key);

  final BoxFit fit;
  final ValueChanged<BarcodeMLKit> qrCodeCallback;
  final Widget? child;
  final WidgetBuilder notStartedBuilder;
  final WidgetBuilder offscreenBuilder;
  final ErrorCallback onError;
  final List<BarcodeFormatsMLKit>? formats;

  @override
  MLKitScannerState createState() => MLKitScannerState();
}

class MLKitScannerState extends State<MLKitScanner> with WidgetsBindingObserver {

  final MLKitScanner = MLKit();
  bool onScreen = true;
  Future<PreviewDetails>? _previewScreen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
    MLKitScanner.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => onScreen = true);
    } else {
      if (_previewScreen != null && onScreen) {
        MLKitScanner.stop();
      }
      setState(() {
        onScreen = false;
        _previewScreen = null;
      });
    }
  }

  /// This method can be used to restart scanning
  ///  the event that it was paused.
  Future<void> restart() async {
    await MLKitScanner.stop();
    setState(() {
      _previewScreen = null;
    });
  }

  /// This method can be used to manually stop the
  /// camera.
  Future<void> stop() async {
    await MLKitScanner.stop();
  }

  Future<PreviewDetails> _initPreviewScreen(num width, num height) async {
    var previewDetails = await MLKitScanner.start(
      width: width.toInt(),
      height: height.toInt(),
      qrCodeHandler: widget.qrCodeCallback,
      formats: widget.formats,
    );
    return previewDetails;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (_previewScreen == null && onScreen) {
        _previewScreen = _initPreviewScreen(constraints.maxWidth, constraints.maxHeight);
      } else if (!onScreen) {
        return widget.offscreenBuilder(context);
      }

      return FutureBuilder(
        future: _previewScreen,
        builder: (BuildContext context, AsyncSnapshot<PreviewDetails> details) {
          switch (details.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return widget.notStartedBuilder(context);
            case ConnectionState.done:
              if (details.hasError) {
                debugPrint(details.error.toString());
                return widget.onError(context, details.error!);
              }
              Widget preview = SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Preview(
                  previewDetails: details.data!,
                  targetWidth: constraints.maxWidth,
                  targetHeight: constraints.maxHeight,
                  fit: widget.fit,
                ),
              );

              if (widget.child != null) {
                return Stack(
                  children: [
                    preview,
                    widget.child!,
                  ],
                );
              }
              return preview;

            default:
              throw AssertionError('${details.connectionState} not supported.');
          }
        },
      );
    });
  }
}

class Preview extends StatelessWidget {
  final double width, height;
  final double targetWidth, targetHeight;
  final int textureId;
  final int sensorOrientation;
  final BoxFit fit;

  Preview({
    required PreviewDetails previewDetails,
    required this.targetWidth,
    required this.targetHeight,
    required this.fit,
  })  : textureId = previewDetails.textureId,
        width = previewDetails.width.toDouble(),
        height = previewDetails.height.toDouble(),
        sensorOrientation = previewDetails.sensorOrientation.toInt();

  @override
  Widget build(BuildContext context) {
    return NativeDeviceOrientationReader(
      builder: (context) {
        var nativeOrientation = NativeDeviceOrientationReader.orientation(context);

        var nativeRotation = 0;
        switch (nativeOrientation) {
          case NativeDeviceOrientation.portraitUp:
            nativeRotation = 0;
            break;
          case NativeDeviceOrientation.landscapeRight:
            nativeRotation = 90;
            break;
          case NativeDeviceOrientation.portraitDown:
            nativeRotation = 180;
            break;
          case NativeDeviceOrientation.landscapeLeft:
            nativeRotation = 270;
            break;
          case NativeDeviceOrientation.unknown:
          default:
            break;
        }

        var rotationCompensation = ((nativeRotation - sensorOrientation + 450) % 360) ~/ 90;

        var frameHeight = width;
        var frameWidth = height;

        return ClipRect(
          child: FittedBox(
            fit: fit,
            child: RotatedBox(
              quarterTurns: rotationCompensation,
              child: SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: Texture(textureId: textureId),
              ),
            ),
          ),
        );
      },
    );
  }
}
