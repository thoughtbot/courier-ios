import Foundation

public protocol URLSession {
  func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> URLSessionTask
}

extension NSURLSession: URLSession {
  public func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> URLSessionTask {
    return dataTaskWithRequest(request, completionHandler: completionHandler) as NSURLSessionDataTask
  }
}
