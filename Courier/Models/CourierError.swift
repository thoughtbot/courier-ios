/**
 Represents errors that occur while communicating with the Courier API.
*/
public enum CourierError: Error {
  /**
   Represents invalid (unexpected) status codes returned by the Courier API.

   - parameter statusCode: The HTTP status code that was returned by the Courier API.
  */
  case invalidStatusCode(Int?)

  /**
   Represents other errors that can occur but aren't explicitely handled.

   - parameter error: The underlying NSError.
  */
  case other(error: NSError)
}

public func == (lerror: CourierError, rerror: CourierError) -> Bool {
  switch (lerror, rerror) {
  case let (.invalidStatusCode(lhs), .invalidStatusCode(rhs)):
    return lhs == rhs
  case let (.other(lhs), .other(rhs)):
    return lhs == rhs
  case (_, _):
    return false
  }
}

extension CourierError: Equatable { }
