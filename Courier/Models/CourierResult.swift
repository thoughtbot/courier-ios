import Foundation

public enum CourierResult {
  case Success
  case Error(CourierError)
}

public func == (lresult: CourierResult, rresult: CourierResult) -> Bool {
  switch (lresult, rresult) {
  case (.Success, .Success): return true
  case let (.Error(lhs), .Error(rhs)): return lhs == rhs
  case (_, _): return false
  }
}
extension CourierResult: Equatable {}

