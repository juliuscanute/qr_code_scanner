enum ReturnStatus { success, failed }

extension ReturnStatusExtension on ReturnStatus {
  bool asBool() {
    return this == ReturnStatus.success;
  }
}
