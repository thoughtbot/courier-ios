import Foundation

public struct Courier {
  public let apiKey: String

  let urlSession = NSURLSession.sharedSession()
  let courierURL = NSURL(string: "https://courier-testing.herokuapp.com/")!

  public init(apiKey: String) {
    self.apiKey = apiKey
  }

  public func subscribeToChannel(channel: String, withToken token: NSData) {
    let subscribeURL = courierURL.URLByAppendingPathComponent("subscribe").URLByAppendingPathComponent(channel)
    let request = NSMutableURLRequest(URL: subscribeURL)
    request.HTTPMethod = "PUT"
    request.setValue("Token token=\(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    request.HTTPBody = HTTPBodyForToken(token)
    NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
      if let error = error {
        NSLog("PUT /subscribe/\(channel) error: \(error)")
      } else if let response = response as? NSHTTPURLResponse {
        NSLog("PUT /subscribe/\(channel) \(response.statusCode)")
      } else {
        NSLog("PUT /subscribe/\(channel) invalid response type \(response)")
      }
    }.resume()
  }
}

private extension Courier {
  func HTTPBodyForToken(token: NSData) -> NSData {
    return try! NSJSONSerialization.dataWithJSONObject(["token": tokenStringFromData(token)], options: [])
  }

  func tokenStringFromData(data: NSData) -> String {
    let tokenChars = UnsafePointer<CChar>(data.bytes)
    var tokenString = ""

    for index in 0..<data.length {
      tokenString += String(format: "%02.2hhx", arguments: [tokenChars[index]])
    }

    return tokenString
  }
}
