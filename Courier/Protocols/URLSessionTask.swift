import Foundation

public protocol URLSessionTask {
  func resume()
}

extension NSURLSessionTask: URLSessionTask {}