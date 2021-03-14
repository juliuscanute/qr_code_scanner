enum BarcodeFormat {
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

extension BarcodeTypesExtension on BarcodeFormat {
  int asInt() {
    return index;
  }

  static BarcodeFormat fromString(String format) {
    switch (format) {
      case 'AZTEC':
        return BarcodeFormat.aztec;
      case 'CODABAR':
        return BarcodeFormat.codabar;
      case 'CODE_39':
        return BarcodeFormat.code39;
      case 'CODE_93':
        return BarcodeFormat.code93;
      case 'CODE_128':
        return BarcodeFormat.code128;
      case 'DATA_MATRIX':
        return BarcodeFormat.dataMatrix;
      case 'EAN_8':
        return BarcodeFormat.ean8;
      case 'EAN_13':
        return BarcodeFormat.ean13;
      case 'ITF':
        return BarcodeFormat.itf;
      case 'MAXICODE':
        return BarcodeFormat.maxicode;
      case 'PDF_417':
        return BarcodeFormat.pdf417;
      case 'QR_CODE':
        return BarcodeFormat.qrcode;
      case 'RSS14':
        return BarcodeFormat.rss14;
      case 'RSS_EXPANDED':
        return BarcodeFormat.rssExpanded;
      case 'UPC_A':
        return BarcodeFormat.upcA;
      case 'UPC_E':
        return BarcodeFormat.upcE;
      case 'UPC_EAN_EXTENSION':
        return BarcodeFormat.upcEanExtension;
      default:
        return BarcodeFormat.unknown;
    }
  }

  String get formatName {
    switch (this) {
      case BarcodeFormat.aztec:
        return 'AZTEC';
      case BarcodeFormat.codabar:
        return 'CODABAR';
      case BarcodeFormat.code39:
        return 'CODE_39';
      case BarcodeFormat.code93:
        return 'CODE_93';
      case BarcodeFormat.code128:
        return 'CODE_128';
      case BarcodeFormat.dataMatrix:
        return 'DATA_MATRIX';
      case BarcodeFormat.ean8:
        return 'EAN_8';
      case BarcodeFormat.ean13:
        return 'EAN_13';
      case BarcodeFormat.itf:
        return 'ITF';
      case BarcodeFormat.maxicode:
        return 'MAXICODE';
      case BarcodeFormat.pdf417:
        return 'PDF_417';
      case BarcodeFormat.qrcode:
        return 'QR_CODE';
      case BarcodeFormat.rss14:
        return 'RSS14';
      case BarcodeFormat.rssExpanded:
        return 'RSS_EXPANDED';
      case BarcodeFormat.upcA:
        return 'UPC_A';
      case BarcodeFormat.upcE:
        return 'UPC_E';
      case BarcodeFormat.upcEanExtension:
        return 'UPC_EAN_EXTENSION';
      default:
        return 'UNKNOWN';
    }
  }
}
