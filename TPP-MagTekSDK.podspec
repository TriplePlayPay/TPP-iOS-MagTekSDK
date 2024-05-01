Pod::Spec.new do |spec|
  spec.name         = "TPP-MagTekSDK"
  spec.version      = "0.0.25"
  spec.summary      = "Triple Play Pay MagTekSDK"
  spec.description  = 'A way to integrate with MagTek hardware from Triple Play Pay'
  spec.homepage     = "https://github.com/TriplePlayPay/TPP-iOS-MagTekSDK"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "Parker Brooks" => "parker@tripleplaypay.com" }
  spec.platform     = :ios, "12.4"
  spec.ios.deployment_target = "12.4"
  spec.source       = { :git => "https://github.com/TriplePlayPay/TPP-iOS-MagTekSDK.git", :tag => "0.0.25" }
  spec.swift_version = "5.0"
  spec.vendored_frameworks = "MagTekSDK.xcframework"
end
