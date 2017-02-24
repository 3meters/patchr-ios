# Open source
source 'https://github.com/CocoaPods/Specs.git'

plugin 'cocoapods-keys', {
  :project => "Patchr",
  :targets => ["Patchr"],
  :keys => [
    "BugsnagKey",
    "BingSubscriptionKey",
    "CreativeSdkClientId",
    "CreativeSdkClientSecret",
    "AwsS3Key",
    "AwsS3Secret",
    "BranchKey"
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
    pod 'SDWebImage',               '~> 3.8.1'
    pod 'UIDevice-Hardware',        '~> 0.1.7'		# Convenience for determining system version and model identifier
    pod 'Bugsnag'                                   # Crash reporting
    pod 'BEMCheckBox'
    pod 'CocoaLumberjack/Swift'
    pod 'CLTokenInputView'
    pod 'Firebase/RemoteConfig'
    pod 'Firebase/Core'
    pod 'Firebase/Crash'
    pod 'Firebase/Auth'
    pod 'Firebase/Database'
    pod 'Firebase/Messaging'
    pod 'FirebaseUI/Database'
    pod 'PopupDialog'
    pod 'SlideMenuControllerSwift'
    pod 'TwicketSegmentedControl'
    pod 'TTTAttributedLabel'
end

plugin 'cocoapods-no-dev-schemes'

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end

# CreativeSDKCore and Image frameworks are on version 0.12.2127.02
