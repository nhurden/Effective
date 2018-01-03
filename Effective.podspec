Pod::Spec.new do |s|
  s.name         = "Effective"
  s.version      = "0.0.1"
  s.summary      = "An extensible state container for Swift"

  s.homepage     = "http://github.com/nhurden/Effective"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author       = { "Nicholas Hurden" => "git@nhurden.com" }

  s.source       = { :git => "https://github.com/nhurden/Effective.git", :tag => "#{s.version}" }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'

  s.requires_arc = true

  s.dependency 'RxSwift', '~> 4.0'
  s.dependency 'RxCocoa', '~> 4.0'

  s.source_files  = "Effective/*.{swift}"
end
