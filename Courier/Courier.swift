import Foundation

public typealias CourierCompletionHandler = (CourierResult) -> Void

public final class Courier {
  static let defaultBaseURL = NSURL(string: "https://courier.thoughtbot.com/")!

  public let apiToken: String
  public let apiVersion = 1

  let urlSession: URLSession
  let baseURL: NSURL
  let environment: Environment

  private let specialCharactersRegex = try! NSRegularExpression(pattern: "[^a-z0-9\\-_]+", options: .CaseInsensitive)
  private let leadingTrailingSeparatorRegex = try! NSRegularExpression(pattern: "^-|-$", options: .CaseInsensitive)
  private let repeatingSeperatorRegex = try! NSRegularExpression(pattern: "-{2,}", options: .CaseInsensitive)

  private var userDefaultsKey: String {
    return "com.thoughtbot.courier.device_token"
  }
  public var deviceToken: NSData? {
    get {
      return NSUserDefaults.standardUserDefaults().dataForKey(userDefaultsKey)
    }
    set {
      NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: userDefaultsKey)
    }
  }

  public init(
    apiToken: String,
    environment: Environment,
    urlSession: URLSession = NSURLSession.sharedSession(),
    baseURL: NSURL = defaultBaseURL
  ) {
    self.apiToken = apiToken
    self.urlSession = urlSession
    self.baseURL = baseURL
    self.environment = environment
  }

  public func subscribeToChannel(channel: String, completionHandler: CourierCompletionHandler? = nil) {
    guard let deviceToken = deviceToken else {
      preconditionFailure(
        "Cannot subscribe to a channel without a device token."
        + "Set courier.deviceToken in your"
        + "UIApplicationDelegate application(_:didRegisterForRemoteNotificationsWithDeviceToken:)"
      )
    }

    subscribeToChannel(channel, withToken: deviceToken, completionHandler: completionHandler)
  }

  public func subscribeToChannel(
    channel: String,
    withToken token: NSData,
    completionHandler: CourierCompletionHandler? = nil
  ) {
    deviceToken = token
    httpRequest("PUT", channel: channel, token: token, completionHandler: completionHandler)
  }

  public func unsubscribeFromChannel(channel: String, completionHandler: CourierCompletionHandler? = nil) {
    guard let deviceToken = deviceToken else {
      preconditionFailure(
        "Cannot subscribe to a channel without a device token."
        + "Set courier.deviceToken in your"
        + "UIApplicationDelegate application(_:didRegisterForRemoteNotificationsWithDeviceToken:)"
      )
    }
    unsubscribeToken(deviceToken, fromChannel: channel, completionHandler: completionHandler)
  }
}

private extension Courier {
  func HTTPBodyForToken(token: NSData) -> NSData {
    return try! NSJSONSerialization.dataWithJSONObject(
      ["device": ["token": tokenStringFromData(token)]], options: []
    )
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
    let transliterated = components.filter { $0 != "" }.joinWithSeparator("-")
    return transliterated.stringByReplacingMatches(specialCharactersRegex, withString: "-")
      .stringByReplacingMatches(leadingTrailingSeparatorRegex, withString: "")
      .stringByReplacingMatches(repeatingSeperatorRegex, withString: "-")
  }

  func unsubscribeToken(token: NSData, fromChannel channel: String, completionHandler: CourierCompletionHandler? = nil) {
    httpRequest("DELETE", channel: channel, token: token, completionHandler: completionHandler)
  }

  private func httpRequest(
    method: String,
    channel: String,
    token: NSData,
    completionHandler: CourierCompletionHandler? = nil
  ) {
    guard let url = URLForChannel(channel, environment: environment) else {
      fatalError("Failed to create URL for channel: \(channel) in environment: \(environment)")
    }

    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = method
    request.HTTPBody = HTTPBodyForToken(token)

    request.setValue("Token token=\(apiToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json version=\(apiVersion)", forHTTPHeaderField: "Accept")

    urlSession.dataTaskWithRequest(request) { data, response, error in
      if let error = error {
        completionHandler?(.Error(.Other(error: error)))
      } else {
        let statusCode = (response as? NSHTTPURLResponse)?.statusCode
        if case .Some(200...299) = statusCode {
          completionHandler?(.Success)
        } else {
          completionHandler?(.Error(.InvalidStatusCode(statusCode)))
        }
      }
    }.resume()
  }

  func URLForChannel(channel: String, environment: Environment) -> NSURL? {
    let components = NSURLComponents()
    components.path = "subscribe/\(self.parameterizeString(channel))"
    components.queryItems = [NSURLQueryItem(name: "environment", value: self.environment.rawValue)]
    return components.URLRelativeToURL(self.baseURL)
  }
}

private extension String {
  func stringByReplacingMatches(regex: NSRegularExpression, withString replacementString: String) -> String {
    let range = NSRange(location: 0, length: startIndex.distanceTo(endIndex))
    return regex.stringByReplacingMatchesInString(self, options: [], range: range, withTemplate: replacementString)
  }
}
