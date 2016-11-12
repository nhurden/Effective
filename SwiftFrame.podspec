Pod::Spec.new do |s|

  s.name         = "SwiftFrame"
  s.version      = "0.0.1"
  s.summary      = "An extensible state container for Swift"

  s.homepage     = "http://github.com/nhurden/SwiftFrame"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author       = { "Nicholas Hurden" => "git@nhurden.com" }

  s.source       = { :git => "https://github.com/nhurden/SwiftFrame.git", :tag => "#{s.version}" }

  s.platform     = :osx, '10.10'
  s.requires_arc = true

  s.dependency 'RxSwift'

  s.source_files  = "SwiftFrame/*.{swift}"
end
