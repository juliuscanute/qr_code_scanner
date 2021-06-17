enum BarcodeFormatQRView {
  /// Aztec 2D barcode format.
  aztec,

  /// CODABAR 1D format.
  /// Not supported in iOS
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
  /// Not supported in iOS.
  maxicode,

  /// PDF417 format.
  pdf417,

  /// QR Code 2D barcode format.
  qrcode,

  /// RSS 14
  /// Not supported in iOS.
  rss14,

  /// RSS EXPANDED
  /// Not supported in iOS.
  rssExpanded,

  /// UPC-A 1D format.
  /// Same as ean-13 on iOS.
  upcA,

  /// UPC-E 1D format.
  upcE,

  /// UPC/EAN extension format. Not a stand-alone format.
  upcEanExtension,

  /// Unknown
  unknown
}

extension BarcodeTypesExtension on BarcodeFormatQRView {
  int asInt() {
    return index;
  }

  static BarcodeFormatQRView fromString(String format) {
    switch (format) {
      case 'AZTEC':
        return BarcodeFormatQRView.aztec;
      case 'CODABAR':
        return BarcodeFormatQRView.codabar;
      case 'CODE_39':
        return BarcodeFormatQRView.code39;
      case 'CODE_93':
        return BarcodeFormatQRView.code93;
      case 'CODE_128':
        return BarcodeFormatQRView.code128;
      case 'DATA_MATRIX':
        return BarcodeFormatQRView.dataMatrix;
      case 'EAN_8':
        return BarcodeFormatQRView.ean8;
      case 'EAN_13':
        return BarcodeFormatQRView.ean13;
      case 'ITF':
        return BarcodeFormatQRView.itf;
      case 'MAXICODE':
        return BarcodeFormatQRView.maxicode;
      case 'PDF_417':
        return BarcodeFormatQRView.pdf417;
      case 'QR_CODE':
        return BarcodeFormatQRView.qrcode;
      case 'RSS14':
        return BarcodeFormatQRView.rss14;
      case 'RSS_EXPANDED':
        return BarcodeFormatQRView.rssExpanded;
      case 'UPC_A':
        return BarcodeFormatQRView.upcA;
      case 'UPC_E':
        return BarcodeFormatQRView.upcE;
      case 'UPC_EAN_EXTENSION':
        return BarcodeFormatQRView.upcEanExtension;
      default:
        return BarcodeFormatQRView.unknown;
    }
  }

  String get formatName {
    switch (this) {
      case BarcodeFormatQRView.aztec:
        return 'AZTEC';
      case BarcodeFormatQRView.codabar:
        return 'CODABAR';
      case BarcodeFormatQRView.code39:
        return 'CODE_39';
      case BarcodeFormatQRView.code93:
        return 'CODE_93';
      case BarcodeFormatQRView.code128:
        return 'CODE_128';
      case BarcodeFormatQRView.dataMatrix:
        return 'DATA_MATRIX';
      case BarcodeFormatQRView.ean8:
        return 'EAN_8';
      case BarcodeFormatQRView.ean13:
        return 'EAN_13';
      case BarcodeFormatQRView.itf:
        return 'ITF';
      case BarcodeFormatQRView.maxicode:
        return 'MAXICODE';
      case BarcodeFormatQRView.pdf417:
        return 'PDF_417';
      case BarcodeFormatQRView.qrcode:
        return 'QR_CODE';
      case BarcodeFormatQRView.rss14:
        return 'RSS14';
      case BarcodeFormatQRView.rssExpanded:
        return 'RSS_EXPANDED';
      case BarcodeFormatQRView.upcA:
        return 'UPC_A';
      case BarcodeFormatQRView.upcE:
        return 'UPC_E';
      case BarcodeFormatQRView.upcEanExtension:
        return 'UPC_EAN_EXTENSION';
      default:
        return 'UNKNOWN';
    }
  }
}
