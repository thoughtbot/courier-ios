import Foundation

/**
 Abstraction of the NSURLSession interface. Used to decouple the Courier client from the underlying HTTP layer used.
 Primarily useful for testing.
*/
public protocol URLSession {
  func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> URLSessionTask
}

/**
 Extensions to make NSURLSession conform to our URLSession interface.

 - seealso: NSURLSession
*/
extension NSURLSession: URLSession {
  /**
   Implementation of the dataTaskWithRequest(_:,completionHandler:) so that we can return our `URLSessionTask` abstraction, instead of the default `NSURLSessionDataTask`.

   - seealso: NSURLSession.dataTaskWithRequest(_:,completionHandler)
  */
  public func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> URLSessionTask {
    return dataTaskWithRequest(request, completionHandler: completionHandler) as NSURLSessionDataTask
  }
}
