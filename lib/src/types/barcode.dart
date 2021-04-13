import 'barcode_format.dart';

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
  final List<int>? rawBytes;

  static Barcode fromJson(Map json) {
    final code = json['code'] as String;
    final rawType = json['type'] as String;
    // Raw bytes are only supported by Android.
    final rawBytes = json['rawBytes'] as List<int>?;
    final format = BarcodeTypesExtension.fromString(rawType);
    if (format != BarcodeFormat.unknown) {
      return Barcode(code, format, rawBytes);
    } else {
      throw Exception('Unexpected barcode type $rawType');
    }
  }
}
