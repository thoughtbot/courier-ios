public enum CourierError: ErrorType {
  case InvalidStatusCode(Int?)
  case Other(error: NSError)
}

public func == (lerror: CourierError, rerror: CourierError) -> Bool {
  switch (lerror, rerror) {
  case let (.InvalidStatusCode(lhs), .InvalidStatusCode(rhs)):
    return lhs == rhs
  case let (.Other(lhs), .Other(rhs)):
    return lhs == rhs
  case (_, _):
    return false
  }
}
extension CourierError: Equatable { }
