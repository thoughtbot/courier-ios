/**
 Represents errors that occur while communicating with the Courier API.
*/
public enum CourierError: ErrorType {
  /**
   Represents invalid (unexpected) status codes returned by the Courier API.

   - parameter statusCode: The HTTP status code that was returned by the Courier API.
  */
  case InvalidStatusCode(Int?)

  /**
   Represents other errors that can occur but aren't explicitely handled.

   - parameter error: The underlying NSError.
  */
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
