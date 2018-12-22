Pod::Spec.new do |s|
  s.name         = "ASReceipt"
  s.version      = "1.0.0"
  s.summary      = "App Store Receipt Parser"
  s.homepage     = "https://github.com/mrdepth/ASReceipt"
  s.license      = "MIT"
  s.author       = { "Shimanski Artem" => "shimanski.artem@gmail.com" }
  s.source       = { :git => "https://github.com/mrdepth/ASReceipt.git", :branch => "master" }
  s.source_files = "Source/*.swift", "Source/Skeleton/*.{h,c}"
  s.private_header_files = "Source/Skeleton/*.h"
  s.platform     = :ios
  s.ios.deployment_target = "9.0"
  s.static_framework = true
  s.swift_version = "4.2"
  s.dependency "openssl", "1.0.0"
  s.xcconfig = {'SWIFT_INCLUDE_PATHS' => '"$(PODS_TARGET_SRCROOT)/Source/Skeleton"'}
  s.libraries = "crypto", "ssl"
end
