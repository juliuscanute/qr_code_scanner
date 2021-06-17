final class Atomic<T> {
  
  private let sema = DispatchSemaphore(value: 1)
  private var _value: T
  
  init (_ value: T) {
    _value = value
  }
  
  var value: T {
    get {
      sema.wait()
      defer {
        sema.signal()
      }
      return _value
    }
    set {
      sema.wait()
      _value = newValue
      sema.signal()
    }
  }
  
  func swap(_ value: T) -> T {
    sema.wait()
    let v = _value
    _value = value
    sema.signal()
    return v
  }
}
