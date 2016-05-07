Pod::Spec.new do |s|
  s.name = "APIModel"
  s.module_name = "ApiModel"
  s.version = "0.11.1"
  s.summary = "Easy API integrations using Realm and Swift"

  s.description  = <<-DESC
                   Easy get up and running with any API, with maximum flexibility,
                   intuitive boilerplate and a very declarative aproach to API integrations.
                   DESC

  s.homepage = "https://github.com/erkie/ApiModel"

  s.license = "MIT"
  s.author = { "Erik Rothoff Andersson" => "erik.rothoff@gmail.com" }
  s.ios.deployment_target = '8.0'
  s.source = { git: "https://github.com/erkie/ApiModel.git", tag: s.version }
  s.source_files  = "Source/**/*"

  s.requires_arc = true
  s.dependency "Alamofire", "~> 3.0"
  s.dependency "SwiftyJSON", "~> 2.3.0"
  s.dependency "RealmSwift", "~> 0.101.0"
end
