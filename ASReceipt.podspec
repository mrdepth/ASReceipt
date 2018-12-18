Pod::Spec.new do |s|
  s.name         = "ASReceipt"
  s.version      = "1.0.0"
  s.summary      = "App Store Receipt Parser"
  s.homepage     = "https://github.com/mrdepth/ASReceipt"
  s.license      = "MIT"
  s.author       = { "Shimanski Artem" => "shimanski.artem@gmail.com" }
  s.source       = { :git => "https://github.com/mrdepth/ASReceipt.git", :branch => "feature/swift_4.2" }
  s.source_files = "Source/*.swift"
  s.platform     = :ios
  s.ios.deployment_target = "9.0"
  s.swift_version = "4.2"
}
end
