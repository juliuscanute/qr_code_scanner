enum ReturnStatus { Success, Failed }

extension ReturnStatusExtension on ReturnStatus {
  bool asBool() {
    return this == ReturnStatus.Success;
  }
}
