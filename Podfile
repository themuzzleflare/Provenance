install! 'cocoapods', :warn_for_unused_master_specs_repo => false

platform :ios, '14.0'
inhibit_all_warnings!

target 'Provenance' do
  use_frameworks!
  
  pod 'Firebase/Crashlytics'
  pod 'Firebase/AnalyticsWithoutAdIdSupport'
  pod 'Firebase/AppCheck'
  pod 'Alamofire'
  pod 'AlamofireNetworkActivityIndicator'
  pod 'SwiftLint'
  pod 'MarqueeLabel'
  pod 'FLAnimatedImage'
  pod 'NotificationBannerSwift'
  pod 'SwiftDate'
  pod 'Texture'
  pod 'SnapKit'
  pod 'IGListKit/Diffing'
  pod 'BonMot'
  
end
  
target 'Provenance Intents' do
  use_frameworks!
  
  pod 'SwiftDate'
  pod 'Alamofire'
  
end

target 'Provenance IntentsUI' do
  use_frameworks!
  
  pod 'SnapKit'
  pod 'SwiftDate'
  
end

target 'Provenance Widgets' do
  use_frameworks!
  
  pod 'SwiftDate'

end

post_install do |installer|
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-Provenance/Pods-Provenance-acknowledgements.plist', 'Provenance/Resources/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
  installer.pods_project.targets.each do |target|
    if target.name == 'PINCache' || target.name == 'PINOperation' || target.name == 'PINRemoteImage' || target.name == 'IGListKit'
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
      end
    else
      if target.name == 'Texture'
        target.build_configurations.each do |config|
          config.build_settings['VALIDATE_WORKSPACE_SKIPPED_SDK_FRAMEWORKS'] = 'AssetsLibrary'
        end
      end
    end
  end
end
