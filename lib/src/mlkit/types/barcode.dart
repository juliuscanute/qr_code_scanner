
import 'package:qr_code_scanner/src/mlkit/types/enums/barcode_value_types.dart';

import 'enums/barcode_formats.dart';

/// The [BarcodeMLKit] object holds information about the barcode or qr code.
///
/// [code] is the content of the barcode.
/// [format] displays which type the code is.
/// Only for Android, [rawBytes] gives a list of bytes of the result.
class BarcodeMLKit {

  final String displayValue;
  final String rawValue;
  final BarcodeValueTypesMLKit valueType;
  final BarcodeFormatsMLKit format;

  BarcodeMLKit({required this.displayValue, required this.rawValue,
    required this.valueType, required this.format});
}
