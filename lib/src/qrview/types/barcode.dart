import 'barcode_format_qrview.dart';

/// The [Barcode] object holds information about the barcode or qr code.
///
/// [code] is the content of the barcode.
/// [format] displays which type the code is.
/// Only for Android, [rawBytes] gives a list of bytes of the result.
class Barcode {
  Barcode(this.code, this.format, this.rawBytes);

  final String code;
  final BarcodeFormatQRView format;

  /// Raw bytes are only supported by Android.
  final List<int>? rawBytes;
}
