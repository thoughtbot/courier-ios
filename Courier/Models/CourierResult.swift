import Foundation

/**
 Represents the Result of communicating with the Courier API.
*/
public enum CourierResult {
  /**
   Communication with the Courier API was successful.
  */
  case success

  /**
   There was an error communicating with the Courier API.
   
   - parameter error: The error that occurred.
  */
  case error(CourierError)
}

/**
*/
public func == (lresult: CourierResult, rresult: CourierResult) -> Bool {
  switch (lresult, rresult) {
  case (.success, .success): return true
  case let (.error(lhs), .error(rhs)): return lhs == rhs
  case (_, _): return false
  }
}
extension CourierResult: Equatable {}
