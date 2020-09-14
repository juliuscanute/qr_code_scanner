enum BarcodeTypes {
  aztec,
  code128,
  code39,
  code93,
  dataMatrix,
  ean13,
  ean8,
  interleaved2of5,
  pdf417,
  qr,
  upce,
}

extension BarcodeTypesExtension on BarcodeTypes {
  int asInt() {
    return index;
  }
}
