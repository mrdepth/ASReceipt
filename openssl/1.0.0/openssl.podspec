Pod::Spec.new do |s|
  s.name = "openssl"
  s.module_name = "openssl"
  s.version      = "1.0.0"
  s.summary      = "App Store Receipt Parser / OpenSSL"
  s.homepage     = "https://github.com/mrdepth/ASReceipt"
  s.license      = "MIT"
  s.author       = { "Shimanski Artem" => "shimanski.artem@gmail.com" }
  s.source       = { :git => "https://github.com/mrdepth/ASReceipt.git", :branch => "pod" }
  s.platform = :ios
  s.ios.deployment_target = "9.0"
  s.static_framework = true
  s.source_files = "Source/ThirdParty/OpenSSL/include/openssl/*.h", "Source/ThirdParty/OpenSSL/openssl.{h,m}"
  s.public_header_files = "Source/ThirdParty/OpenSSL/include/openssl/*.h", "Source/ThirdParty/OpenSSL/openssl.h"
#s.vendored_libraries = "Source/ThirdParty/OpenSSL/lib/libcrypto.a", "Source/ThirdParty/OpenSSL/lib/libssl.a"
#s.libraries = "crypto", "ssl"
  s.module_map = "Source/ThirdParty/OpenSSL/iOS/module.modulemap"
  s.preserve_path = "Source/ThirdParty/OpenSSL/lib/*.a"
  s.pod_target_xcconfig = { 'WARNING_CFLAGS' => '-Wno-incomplete-umbrella',
							'LIBRARY_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/Source/ThirdParty/OpenSSL/lib',
							'OTHER_LDFLAGS' => '-lcrypto -lssl' }
end
