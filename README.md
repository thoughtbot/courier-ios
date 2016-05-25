# Courier iOS [![Build status](https://circleci.com/gh/thoughtbot/courier-ios.svg?style=shield&circle-token=061ff707780f9fb3093d68d5dbf909e2cdf8099a)](https://circleci.com/gh/thoughtbot/courier-ios)

iOS framework for integrating with the [Courier API].

[Courier API]: https://courier.thoughtbot.com

## Installation

### [Carthage]

[Carthage]: https://github.com/Carthage/Carthage

Add the following to your Cartfile:

```
github "thoughtbout/courier-ios"
```

then run `carthage update`.

Follow the current instructions in [Carthage's README][carthage-installation] for up to date installation instructions.

[carthage-installation]:
https://github.com/Carthage/Carthage#adding-frameworks-to-an-application

### [CocoaPods]

[CocoaPods]: http://cocoapods.org

Add the following to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html):

```ruby
pod "courier-ios"
```

You will also need to make sure you're opting into using frameworks:

```ruby
use_frameworks!
```

Then run `pod install` with CocoaPods 0.36 or newer.

### Usage

Instantiate a Courier instance with your app's API token and an environment:

```swift
let courier = Courier.init(apiToken: "[YOUR_API_TOKEN]", environment: .Development)
```

For the environment choose `.Development` if you're sending notifications to a development build of your app. If you're sending notification to an app signed with a distribution certificate (TestFlight, HockeyApp, AppStore, etc) use `.Production`.

Register your app for remote notifications:

```swift
let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: .None)
application.registerUserNotificationSettings(notificationSettings)
application.registerForRemoteNotifications()
```

Send the device token and subscribe it to a channel by implementing:
`application:didRegisterForRemoteNotificationsWithDeviceToken:`:

```swift
func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
  courier.subscribeToChannel("[CHANNEL_NAME]", withToken: deviceToken)
}
```

Alternatively register a token first, and subscribe to a channel later:

```swift
func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
  courier.deviceToken = deviceToken
}
```

```swift
courier.subscribeToChannel("[CHANNEL_NAME]")
```

Courier stores the device token in [user defaults] using a key based on your API token. As long as each Courier instance is using the same API token, It's safe to use multiple instances in your app. 

[user defaults]: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSUserDefaults_Class/

After subscribing to a channel broadcast a notification to it:

```
$ curl -X POST \
-d '{"broadcast": { "payload": { "alert": "Hello From Courier" }}}' \
-H "Content-Type: application/json" \
-H "Authorization: Token token=[YOUR_API_TOKEN]" \
-H "Accept: application/json version=1" \
"https://courier.thoughtbot.com/broadcast/[CHANNEL_NAME]?environment=development"
```

## Contributing

See the [CONTRIBUTING] document. Thank you, [contributors]!

[CONTRIBUTING]: CONTRIBUTING.md
[contributors]: https://github.com/thoughtbot/courier-ios/graphs/contributors

## License

Courier iOS is Copyright (c) 2016 thoughtbot, inc. It is free software, and may be redistributed under the terms specified in the [LICENSE] file.

[LICENSE]: /LICENSE

## About

![thoughtbot](https://thoughtbot.com/logo.png)

Courier iOS is maintained and funded by thoughtbot, inc. The names and logos for thoughtbot are trademarks of thoughtbot, inc.

We love open source software! See [our other projects][community] or look at
our product [case studies] and [hire us][hire] to help build your iOS app.

[community]: https://thoughtbot.com/community?utm_source=github
[case studies]: https://thoughtbot.com/ios?utm_source=github
[hire]: https://thoughtbot.com/hire-us?utm_source=github
