# Uncomment the next line to define a global platform for your project

def rx
  pod 'RxSwift', '~> 4.0'
  pod 'RxCocoa', '~> 4.0'
end

def rx_test
  pod 'RxTest', '~> 4.0'
end

target 'Effective_macOS' do
  platform :osx, '10.10'
  use_frameworks!
  rx

  target 'EffectiveTests_macOS' do
    inherit! :search_paths
    rx_test
  end
end


target 'Effective_iOS' do
  platform :ios, '8.0'
  use_frameworks!
  rx

  target 'EffectiveTests_iOS' do
    inherit! :search_paths
    rx_test
  end
end

