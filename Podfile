# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'OnTrack' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for OnTrack

  #Networking
  pod 'Alamofire'
  pod 'SwiftyJSON'
  pod 'RealmSwift'
  pod 'Starscream', '~> 2.0.4'
  pod 'ActionCableClient'
  
  #UI
  pod 'QRCode'
  pod 'Pulsator'
  pod 'PinCodeTextField', :git => 'https://github.com/tkach/PinCodeTextField'
  pod 'RevealingSplashView'
  pod 'TwicketSegmentedControl'
  pod 'ChameleonFramework/Swift', :git => 'https://github.com/ViccAlexander/Chameleon.git'
  pod 'SCLAlertView'
  pod 'ACProgressHUD-Swift', '~> 1.2'
  pod 'QRCodeReader.swift', '~> 7.4.1'
  pod 'MKRingProgressView'
  pod 'BTNavigationDropdownMenu', :git => 'https://github.com/PhamBaTho/BTNavigationDropdownMenu.git', :branch => 'swift-3.0'
  pod 'BWWalkthrough'
  pod 'Charts'
  pod 'ScrollableGraphView'
  pod 'UICircularProgressRing'
  pod 'AZDialogView'
  pod 'Pageboy', '~> 2.0'
  pod 'Kingfisher', '~> 4.0'
  pod 'Turf'
  
  
  #UN COMMENT!
  #MapBox
  pod 'MapboxNavigation', '~> 0.12'
  pod 'MapboxCoreNavigation', '~> 0.12'
  
  #Fabric
  pod 'Fabric'
  pod 'Crashlytics'
  
  #Helpers
  pod 'SwiftDate', '~> 4.0'
  pod 'SquarePointOfSaleSDK'
  pod 'DateToolsSwift'
  
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if ['Alamofire', 'RealmSwift', 'ActionCableClient', 'QRCode', 'Pulsator', 'PinCodeTextField', 'RevealingSplashView', 'TwicketSegmentedControl', 'ChameleonFramework/Swift', 'SCLAlertView', 'ACProgressHUD-Swift', 'QRCodeReader.swift', 'MKRingProgressView', 'BTNavigationDropdownMenu', 'BWWalkthrough', 'Charts', 'ScrollableGraphView', 'UICircularProgressRing', 'AZDialogView', 'Pageboy', 'Kingfisher', 'Fabric', 'Crashlytics', 'SwiftDate', 'SquarePointOfSaleSDK', 'DateToolsSwift', 'Starscream'].include? target.name
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '3.2'
            end
        end
    end
end

