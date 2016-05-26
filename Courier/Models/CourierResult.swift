import Foundation

/**
 Represents the Result of communicating with the Courier API.
*/
public enum CourierResult {
  /**
   Communication with the Courier API was successful.
  */
  case Success

  /**
   There was an error communicating with the Courier API.
   
   - parameter error: The error that occurred.
  */
  case Error(CourierError)
}

/**
*/
public func == (lresult: CourierResult, rresult: CourierResult) -> Bool {
  switch (lresult, rresult) {
  case (.Success, .Success): return true
  case let (.Error(lhs), .Error(rhs)): return lhs == rhs
  case (_, _): return false
  }
}
extension CourierResult: Equatable {}
