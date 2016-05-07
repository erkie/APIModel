platform :ios, '8.0'

source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

def realm_dep
  pod 'RealmSwift', '~> 0.101.0'

end

target :ApiModel do
  realm_dep

  pod 'Alamofire', '~> 3.0.0'
  pod 'SwiftyJSON', '~> 2.3.0'
end

target :Tests do
  realm_dep

  pod 'Alamofire', '~> 3.0.0'
  pod 'SwiftyJSON', '~> 2.3.0'
  pod 'OHHTTPStubs'
  pod 'OHHTTPStubs/Swift'
end
