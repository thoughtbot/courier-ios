import Foundation

/**
 Abstraction of the NSURLSessionTask interface. Used to decouple the Courier client from the underlying HTTP layer used.
 Primarily useful for testing.
 */
public protocol URLSessionTaskProtocol {
  func resume()
}

/**
 Extensions to make NSURLSession conform to our URLSession interface.

 - seealso: NSURLSession
*/
extension Foundation.URLSessionTask: URLSessionTaskProtocol {}
