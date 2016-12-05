Pod::Spec.new do |s|
  s.name = "courier-notifications"
  s.version = "0.2.0"
  s.summary = "Simple Push Notifications."
  s.homepage = "https://courier.thoughtbot.com"
  s.license = { type: "MIT", file: "LICENSE" }
  s.author = {
    "Nick Charlton" => "nick@nickcharlton.net",
    "Klaas Pieter Annema" => "kpa@annema.me",
    "thoughtbot" => nil,
  }
  s.social_media_url = "http://twitter.com/thoughtbot"
  s.platform = :ios
  s.ios.deployment_target = "8.4"
  s.source = {
    git: "https://github.com/thoughtbot/courier-ios.git",
    tag: "v#{s.version}",
  }
  s.source_files = "Courier", "Courier/**/*.{h,m,swift}"
end
