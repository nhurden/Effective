Pod::Spec.new do |s|

  s.name         = "SwiftFrame"
  s.version      = "0.0.1"
  s.summary      = "An extensible state container for Swift"

  s.description  = <<-DESC
                   DESC

  s.homepage     = "http://github.com/nhurden/SwiftFrame"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author       = { "Nicholas Hurden" => "git@nhurden.com" }

  s.source       = { :git => "http://github.com/nhurden/SwiftFrame.git", :tag => "#{s.version}" }

  s.requires_arc = true

  s.source_files  = "SwiftFrame/*.{swift}"
end
