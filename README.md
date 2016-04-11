# Courier iOS

iOS framework for integrating with the [Courier web service][]

[Courier web service]: https://github.com/thoughtbot/courier-web

## Installation

### Carthage

[Carthage]: https://github.com/Carthage/Carthage

Add the following to your Cartfile:

```
github "thoughtbout/courier-ios"
```

then run `carthage update`.

Follow the current instructions in [Carthage's README][carthage-installation]
for up to date installation instructions.

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

Instantiate a Courier instance with your app's API key:

```swift
let courier = Courier.init(apiKey: "[YOUR_API_KEY]")
```

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

Send a notification to the device:

```
$ curl -X POST \ -d '{"broadcast": { "alert": "Hello From Courier" }}' \
    -H "Content-Type: application/json" \
    -H "Authorization: Token token=[YOUR_API_KEY]" \
    https://courier-staging.herokuapp.com/broadcast/[CHANNEL NAME]
```

## Contributing

See the [CONTRIBUTING] document. Thank you, [contributors]!

[CONTRIBUTING]: CONTRIBUTING.md
[contributors]: https://github.com/thoughtbot/courier-ios/graphs/contributors

## License

Courier iOS is Copyright (c) 2016 thoughtbot, inc. It is free software, and may be
redistributed under the terms specified in the [LICENSE] file.

[LICENSE]: /LICENSE

## About

![thoughtbot](https://thoughtbot.com/logo.png)

Courier iOS is maintained and funded by thoughtbot, inc. The names and logos for
thoughtbot are trademarks of thoughtbot, inc.

We love open source software! See [our other projects][community] or look at
our product [case studies] and [hire us][hire] to help build your iOS app.

[community]: https://thoughtbot.com/community?utm_source=github
[case studies]: https://thoughtbot.com/ios?utm_source=github
[hire]: https://thoughtbot.com/hire-us?utm_source=github
