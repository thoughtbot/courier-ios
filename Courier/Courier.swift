import Foundation

public struct Courier {
  static let defaultBaseURL = NSURL(string: "https://courier.thoughtbot.com/")!

  public let apiKey: String
  public let apiVersion = 1

  let urlSession: URLSession
  let baseURL: NSURL
  let environment: Environment

  public init(
    apiKey: String,
    urlSession: URLSession = NSURLSession.sharedSession(),
    baseURL: NSURL = defaultBaseURL,
    environment: Environment = .Production
  ) {
    self.apiKey = apiKey
    self.urlSession = urlSession
    self.baseURL = baseURL
    self.environment = environment
  }

  public func subscribeToChannel(channel: String, withToken token: NSData) {
    guard let url = URLForChannel(channel, environment: environment) else {
      fatalError("Failed to URL for channel: \(channel) for environment: \(environment)")
    }
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = "PUT"
    request.setValue("Token token=\(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json version=\(apiVersion)", forHTTPHeaderField: "Accept")

    request.HTTPBody = HTTPBodyForToken(token)
    urlSession.dataTaskWithRequest(request) { data, response, error in
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
    return try! NSJSONSerialization.dataWithJSONObject(["device": ["token": tokenStringFromData(token)]], options: [])
  }

  func tokenStringFromData(data: NSData) -> String {
    let tokenChars = UnsafePointer<CChar>(data.bytes)
    var tokenString = ""

    for index in 0..<data.length {
      tokenString += String(format: "%02.2hhx", arguments: [tokenChars[index]])
    }

    return tokenString
  }

  func parameterizeString(string: String) -> String {
    let mutableString = NSMutableString(string: string)
    CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
    CFStringTransform(mutableString, nil, kCFStringTransformStripCombiningMarks, false)
    CFStringLowercase(mutableString, CFLocaleCopyCurrent())

    let components = (mutableString as String).componentsSeparatedByCharactersInSet(.whitespaceAndNewlineCharacterSet())
    return components.filter { $0 != "" }.joinWithSeparator("-")
  }

  func URLForChannel(channel: String, environment: Environment) -> NSURL? {
    let components = NSURLComponents()
    components.path = "subscribe/\(self.parameterizeString(channel))"
    components.queryItems = [NSURLQueryItem(name: "environment", value: self.environment.rawValue)]
    return components.URLRelativeToURL(self.baseURL)
  }
}
