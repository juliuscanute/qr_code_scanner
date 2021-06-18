
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/src/mlkit/types/barcode_value_types.dart';

import 'barcode_formats.dart';

/// The [BarcodeMLKit] object holds information about the barcode or qr code.
class BarcodeMLKit {

  final String displayValue;
  final String rawValue;
  final BarcodeValueTypesMLKit valueType;
  final BarcodeFormatsMLKit format;
  final Rect? boundingBox;

  BarcodeMLKit({required this.displayValue, required this.rawValue,
    required this.valueType, required this.format, this.boundingBox});
}
