import Foundation

public typealias CourierCompletionHandler = (CourierResult) -> Void

/**
 Responsible for authenticating and communicating with an App in the Courier API.
*/
public final class Courier {
  static let defaultBaseURL = NSURL(string: "https://courier.thoughtbot.com/")!

  /**
   The Courier App API token. Find the API token on your app's page at [https://courier.thoughtbot.com](https://courier.thoughtbot.com).
  */
  public let apiToken: String

  /**
   The API version this client instance is using. The default is to always the latest API version.
  */
  public let apiVersion = 1

  /**
   The URLSession used by this instance. The default is `NSURLSession.sharedSession`.
  */
  let urlSession: URLSession

  /**
   The Courier API base URL this instance is communicating with. The default is https://courier.thoughtbot.com.
  */
  let baseURL: NSURL

  /**
   The environment used to communicate with the Courier API.

   - seealso: `Environment` to learn which environment is appropriate.
  */
  let environment: Environment

  private let specialCharactersRegex = try! NSRegularExpression(pattern: "[^a-z0-9\\-_]+", options: .CaseInsensitive)
  private let leadingTrailingSeparatorRegex = try! NSRegularExpression(pattern: "^-|-$", options: .CaseInsensitive)
  private let repeatingSeperatorRegex = try! NSRegularExpression(pattern: "-{2,}", options: .CaseInsensitive)

  private var userDefaultsKey: String {
    return "com.thoughtbot.courier.device_token"
  }

  /**
   Your app's device token as provided by UIKit.

   Obtained by [registering for remote notifications] and implementing
   `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
   in your `UIApplicationDelegate`.

   The `deviceToken` is stored in `NSUserDefaults` when set, making it safe to use
   different `Courier` instances in your app. However the token can change so it's important
   to update Courier every time the `UIApplicationDelegate` method is called.

   [registering for remote notifications]: https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/IPhoneOSClientImp.html#//apple_ref/doc/uid/TP40008194-CH103-SW2
  */
  public var deviceToken: NSData? {
    get {
      return NSUserDefaults.standardUserDefaults().dataForKey(userDefaultsKey)
    }
    set {
      NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: userDefaultsKey)
    }
  }

  /**
    Initialize a Courier client.

    - parameters:
      - apiToken: The Courier App API token. Find the API token on your app's page at [https://courier.thoughtbot.com](https://courier.thoughtbot.com).
      - environment: The environment to use with Courier.
      - urlSession: The URLSession used by this instance. The default is `NSURLSession.sharedSession()`. You should rarely, if ever, have to change this.
      - baseURL: The Courier API base URL to communicating with. The default is https://courier.thoughtbot.com. You should rarely, if ever, have to change this.

    - seealso: `Environment` to learn which environment is appropriate.

    - returns: A new Courier instance configured to work with a Courier app in a particular environment.
  */
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

  /**
    Subscribe to a channel.

    - parameters:
      - channel: The channel name to subscribe to.
      - completionHandler: An optional completion handler to call when the request is complete.

    - precondition: The deviceToken must be non-nil.

    - seealso: subscribeToChannel(_:,withToken:completionHandler:)
  */
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

  /**
   Subscribe device with token to a channel.

   - parameters:
     - channel: The channel name to subscribe to. Special characters will be replaced with 'pretty' alternatives. For example channel name “Tést/chännél!” will become “test-channel”.
     - token: The device token to subscribe with.
     - completionHandler: An optional completion handler to call when the request is complete.
  */
  public func subscribeToChannel(
    channel: String,
    withToken token: NSData,
    completionHandler: CourierCompletionHandler? = nil
  ) {
    deviceToken = token
    httpRequest("PUT", channel: channel, token: token, completionHandler: completionHandler)
  }

  /**
   Unsubscribe device from a channel.
   
   - parameters:
     - channel: The channel name to unsubscribe from.
     - completionHandler: An optional completion handler to call when the request is complete.

   - precondition: The deviceToken must be non-nil.
  */
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

  /**
   Replaces special characters in a string so that it may be used as part of a ‘pretty’ URL.

   - parameters: string The string to parameterize.

   - returns: A string with special characters replaced with 'pretty' alternatives.

   - seealso: [ActiveSupport::Inflector#parameterize](http://apidock.com/rails/ActiveSupport/Inflector/parameterize)
  */
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
