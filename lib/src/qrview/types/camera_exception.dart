/// This is thrown when the plugin reports an error.
class CameraException implements Exception {
  /// Creates a new camera exception with the given error code and description.
  CameraException(this.code, this.description);

  /// Error code.
  String code;

  /// Textual description of the error.
  String? description;

  @override
  String toString() => 'CameraException($code, $description)';
}
