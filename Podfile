# Open source
source 'https://github.com/CocoaPods/Specs.git'

plugin 'cocoapods-keys', {
  :project => "Patchr",
  :targets => ["Patchr"],
  :keys => [
    "AwsS3Secret",              # p1
    "BingSubscriptionKey",      # p1
    "BugsnagKey",               # p3
    "CreativeSdkClientSecret",  # p2
    "BranchKey"                 # p3
  ]
}

platform :ios, '9.0'
inhibit_all_warnings!
use_frameworks!

target 'Patchr' do
    pod 'AFNetworking',             '~> 2.6'
    pod 'AFNetworkActivityLogger',  '~> 2.0'
    pod 'AWSS3',                    '2.4.9'
    pod 'Branch',                   '~> 0.12.5'     # Url routing and deep linking
    pod 'DateTools',                :git => 'https://github.com/MatthewYork/DateTools', :branch => 'swift'
    pod 'DLRadioButton',            '~> 1.4.9'
    pod 'Facade',                   '~> 1.1.1'	    # Convenience methods for frame based layout
    pod 'iRate',                    '~> 1.11.6'
    pod 'IDMPhotoBrowser',          :path => '~/code/IDMPhotoBrowser'
    pod 'MBProgressHUD',            '~> 0.9.1'
    pod 'NHBalancedFlowLayout',     '~> 0.2'
    pod 'pop',                      '~> 1.0'		# Animation library
    pod 'PhoneNumberKit',           '~> 1.0'
    pod 'PBWebViewController',      '~> 0.5'		# Used to show show web content for terms/policy/licensing
    pod 'ReachabilitySwift',        '~> 3'
    pod 'SkyFloatingLabelTextField','~> 2.0.0'
    pod 'SlackTextViewController',  :path => '~/code/SlackTextViewController'
    pod 'SDWebImage/GIF',           '~> 4.0'
    pod 'UIDevice-Hardware',        '~> 0.1.7'		# Convenience for determining system version and model identifier
    pod 'AlertOnboarding'
    pod 'Bugsnag'                                   # Crash reporting
    pod 'BEMCheckBox'
    pod 'CocoaLumberjack/Swift'
    pod 'CLTokenInputView'
    pod 'Emoji-swift'
    pod 'Firebase/RemoteConfig'
    pod 'Firebase/Core'
    pod 'Firebase/Crash'
    pod 'Firebase/Auth'
    pod 'Firebase/Database'
    pod 'Firebase/Messaging'
    pod 'FirebaseUI/Database'
    pod 'PopupDialog'
    pod 'SlideMenuControllerSwift', :path => '~/code/SlideMenuControllerSwift'
    pod 'STPopup'
    pod 'TwicketSegmentedControl'
    pod 'TTTAttributedLabel'
    pod 'VTAcknowledgementsViewController'
end

plugin 'cocoapods-no-dev-schemes'

post_install do |installer|
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods-Patchr/Pods-Patchr-acknowledgements.plist', 'Patchr/Pods-acknowledgements.plist', :remove_destination => true)
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end

# CreativeSDKCore and Image frameworks are on version 0.12.2127.02
