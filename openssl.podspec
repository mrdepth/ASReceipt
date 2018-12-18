Pod::Spec.new do |s|
	s.name = "openssl"
	s.version      = "1.0.0"
	s.summary      = "App Store Receipt Parser"
	s.homepage     = "https://github.com/mrdepth/ASReceipt"
	s.license      = "MIT"
	s.author       = { "Shimanski Artem" => "shimanski.artem@gmail.com" }
	s.source       = { :git => "https://github.com/mrdepth/ASReceipt.git", :branch => "feature/swift_4.2" }
	s.platform = :ios
  s.static_framework = true
  s.source_files = "Source/ThirdParty/OpenSSL/include/openssl/*.h"
#s.public_header_files = "Source/ThirdParty/OpenSSL/include/openssl/*.h"
  s.vendored_libraries = "Source/ThirdParty/OpenSSL/lib/libcrypto.a", "Source/ThirdParty/OpenSSL/lib/libssl.a"
end
