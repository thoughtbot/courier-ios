import Foundation

/**
 Abstraction of the NSURLSession interface. Used to decouple the Courier client from the underlying HTTP layer used.
 Primarily useful for testing.
*/
public protocol URLSessionProtocol {
  func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionTaskProtocol
}

/**
 Extensions to make NSURLSession conform to our URLSession interface.

 - seealso: NSURLSession
*/
extension Foundation.URLSession: URLSessionProtocol {
  /**
   Implementation of the dataTaskWithRequest(_:,completionHandler:) so that we can return our `URLSessionTask` abstraction, instead of the default `NSURLSessionDataTask`.

   - seealso: NSURLSession.dataTaskWithRequest(_:,completionHandler)
  */
  public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionTaskProtocol {
    return dataTask(with: request, completionHandler: completionHandler) as Foundation.URLSessionDataTask
  }
}
