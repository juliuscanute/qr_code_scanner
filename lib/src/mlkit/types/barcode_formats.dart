enum BarcodeFormatsMLKit {
  UNKNOWN,
  ALL_FORMATS,
  CODE_128,
  CODE_39,
  CODE_93,
  CODABAR,
  DATA_MATRIX,
  EAN_13,
  EAN_8,
  ITF,
  QR_CODE,
  UPC_A,
  UPC_E,
  PDF417,
  AZTEC
}

extension BarcodeFormatsMLKitExtension on BarcodeFormatsMLKit {

  int get value {
    switch (this) {
      case BarcodeFormatsMLKit.UNKNOWN:
        return 0;
      case BarcodeFormatsMLKit.ALL_FORMATS:
        return 0xFFFF;
      case BarcodeFormatsMLKit.CODE_128:
        return 0x0001;
      case BarcodeFormatsMLKit.CODE_39:
        return 0x0002;
      case BarcodeFormatsMLKit.CODE_93:
        return 0x0004;
      case BarcodeFormatsMLKit.CODABAR:
        return 0x0008;
      case BarcodeFormatsMLKit.DATA_MATRIX:
        return 0x0010;
      case BarcodeFormatsMLKit.EAN_13:
        return 0x0020;
      case BarcodeFormatsMLKit.EAN_8:
        return 0x0040;
      case BarcodeFormatsMLKit.ITF:
        return 0x0080;
      case BarcodeFormatsMLKit.QR_CODE:
        return 0x0100;
      case BarcodeFormatsMLKit.UPC_A:
        return 0x0200;
      case BarcodeFormatsMLKit.UPC_E:
        return 0x0400;
      case BarcodeFormatsMLKit.PDF417:
        return 0x0800;
      case BarcodeFormatsMLKit.AZTEC:
        return 0x1000;
    }
  }

}