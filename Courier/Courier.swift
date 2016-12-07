import Foundation

public typealias CourierCompletionHandler = (CourierResult) -> Void

/**
 Responsible for authenticating and communicating with an App in the Courier API.
*/
public final class Courier {
  static let defaultBaseURL = URL(string: "https://courier.thoughtbot.com/")!

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
  let urlSession: URLSessionProtocol

  /**
   The Courier API base URL this instance is communicating with. The default is https://courier.thoughtbot.com.
  */
  let baseURL: URL

  /**
   The environment used to communicate with the Courier API.

   - seealso: `Environment` to learn which environment is appropriate.
  */
  let environment: Environment

  fileprivate let specialCharactersRegex = try! NSRegularExpression(pattern: "[^a-z0-9\\-_]+", options: .caseInsensitive)
  fileprivate let leadingTrailingSeparatorRegex = try! NSRegularExpression(pattern: "^-|-$", options: .caseInsensitive)
  fileprivate let repeatingSeperatorRegex = try! NSRegularExpression(pattern: "-{2,}", options: .caseInsensitive)

  fileprivate var userDefaultsKey: String {
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
  public var deviceToken: Data? {
    get {
      return UserDefaults.standard.data(forKey: userDefaultsKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
    }
  }

  /**
    Initialize a Courier client.

    - parameters:
      - apiToken: The Courier App API token. Find the API token on your app's page at [https://courier.thoughtbot.com](https://courier.thoughtbot.com).
      - environment: The environment to use with Courier.
      - urlSession: The URLSession used by this instance. The default is `Foundation.URLSession.shared`. You should rarely, if ever, have to change this.
      - baseURL: The Courier API base URL to communicating with. The default is https://courier.thoughtbot.com. You should rarely, if ever, have to change this.

    - seealso: `Environment` to learn which environment is appropriate.

    - returns: A new Courier instance configured to work with a Courier app in a particular environment.
  */
  public init(
    apiToken: String,
    environment: Environment,
    urlSession: URLSessionProtocol = Foundation.URLSession.shared,
    baseURL: URL = defaultBaseURL
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
  public func subscribeToChannel(_ channel: String, completionHandler: CourierCompletionHandler? = nil) {
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
    _ channel: String,
    withToken token: Data,
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
  public func unsubscribeFromChannel(_ channel: String, completionHandler: CourierCompletionHandler? = nil) {
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
  func HTTPBodyForToken(_ token: Data) -> Data {
    do {
      return try JSONSerialization.data(withJSONObject: ["device": ["token": tokenStringFromData(token)]], options: [])
    } catch {
      preconditionFailure("Couldn't create JSON from token string")
    }
  }

  func tokenStringFromData(_ data: Data) -> String {
    let tokenChars = (data as NSData).bytes.bindMemory(to: CChar.self, capacity: data.count)
    var tokenString = ""

    for index in 0..<data.count {
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
  func parameterizeString(_ string: String) -> String {
    let mutableString = NSMutableString(string: string)
    CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
    CFStringTransform(mutableString, nil, kCFStringTransformStripCombiningMarks, false)
    CFStringLowercase(mutableString, CFLocaleCopyCurrent())

    let components = mutableString.components(separatedBy: .whitespacesAndNewlines)
    let transliterated = components.filter { $0 != "" }.joined(separator: "-")
    return transliterated.stringByReplacingMatches(specialCharactersRegex, withString: "-")
      .stringByReplacingMatches(leadingTrailingSeparatorRegex, withString: "")
      .stringByReplacingMatches(repeatingSeperatorRegex, withString: "-")
  }

  func unsubscribeToken(_ token: Data, fromChannel channel: String, completionHandler: CourierCompletionHandler? = nil) {
    httpRequest("DELETE", channel: channel, token: token, completionHandler: completionHandler)
  }

  func httpRequest(
    _ method: String,
    channel: String,
    token: Data,
    completionHandler: CourierCompletionHandler? = nil
  ) {
    guard let url = URLForChannel(channel, environment: environment) else {
      fatalError("Failed to create URL for channel: \(channel) in environment: \(environment)")
    }

    let request = NSMutableURLRequest(url: url)
    request.httpMethod = method
    request.httpBody = HTTPBodyForToken(token)

    request.setValue("Token token=\(apiToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json version=\(apiVersion)", forHTTPHeaderField: "Accept")

    urlSession.dataTask(with: request as URLRequest) { data, response, error in
      if let error = error {
        completionHandler?(.error(.other(error: error as NSError)))
      } else {
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        if case .some(200...299) = statusCode {
          completionHandler?(.success)
        } else {
          completionHandler?(.error(.invalidStatusCode(statusCode)))
        }
      }
    }.resume()
  }

  func URLForChannel(_ channel: String, environment: Environment) -> URL? {
    var components = URLComponents()
    components.path = "subscribe/\(self.parameterizeString(channel))"
    components.queryItems = [URLQueryItem(name: "environment", value: self.environment.rawValue)]
    return components.url(relativeTo: self.baseURL)
  }
}

private extension String {
  func stringByReplacingMatches(_ regex: NSRegularExpression, withString replacementString: String) -> String {
    let range = NSRange(location: 0, length: characters.distance(from: startIndex, to: endIndex))
    return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replacementString)
  }
}
