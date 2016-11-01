# Open source
source 'https://github.com/CocoaPods/Specs.git'

plugin 'cocoapods-keys', {
  :project => "Patchr",
  :targets => ["Patchr", "PatchrShare"],
  :keys => [
    "BugsnagKey",
    "BingSubscriptionKey",
    "CreativeSdkClientId",
    "CreativeSdkClientSecret",
    "AwsS3Key",
    "AwsS3Secret",
    "BranchKey",
    "ProxibaseSecret",
    "FacebookToken"
  ]
}

platform :ios, '8.0'
inhibit_all_warnings!
use_frameworks!

target 'Patchr' do
    pod 'IDMPhotoBrowser', :path => '~/code/IDMPhotoBrowser'
    pod 'SDWebImage',               '~> 3.8.1'
    pod 'Lockbox',                  '~> 3.0.1'		# Used to protect secrets and install info
    pod 'AWSS3',                    '2.4.9'
    pod 'AFNetworking',             '~> 2.6'
    pod 'AFNetworkActivityLogger',  '~> 2.0'
    pod 'PBWebViewController',      '~> 0.5'		# Used to show show web content for terms/policy/licensing
    pod 'MBProgressHUD',            '~> 0.9.1'
    pod 'DLRadioButton',            '~> 1.4.9'
    pod 'NHBalancedFlowLayout',     '~> 0.2'
    pod 'UIDevice-Hardware',        '~> 0.1.7'		# Convenience for determining system version and model identifier
    pod 'pop',                      '~> 1.0'		# Animation library
    pod 'TWMessageBarManager',      '~> 1.8'		# In-app notifications
    pod 'Facade',                   '~> 1.1.1'	    # Convenience methods for frame based layout
    pod 'THContactPicker',          '~> 1.2'		# Used in message edit
    pod 'DateTools',                '~> 1.7.0'
    pod 'iRate',                    '~> 1.11.6'
    pod 'Branch',                   '~> 0.12.5'     # Url routing and deep linking
    pod 'OneSignal',                '~> 2.0.10'
    pod 'ReachabilitySwift',        '~> 3'
    pod 'Bugsnag'                                   # Crash reporting
    pod 'SwiftyBeaver'
    pod 'JVFloatLabeledTextField',  '~> 1.1'
    pod 'RxSwift',                  '3.0.0-beta.2'
    pod 'RxCocoa',                  '3.0.0-beta.2'
    pod 'PhoneNumberKit',           '~> 1.0'
    pod 'SlideMenuControllerSwift'
    pod 'FontAwesome.swift',        :git=>'https://github.com/thii/FontAwesome.swift.git'
    pod 'Firebase/RemoteConfig'
    pod 'Firebase/Core'
    pod 'Firebase/Crash'
    pod 'Firebase/Auth'
    pod 'Firebase/Database'
    pod 'FirebaseUI/Database',      '~> 0.6'
end

target 'PatchrShare' do
  pod 'SDWebImage',               '~> 3.8.1'
  pod 'AWSS3',                    '2.4.9'
  pod 'Lockbox',                  '~> 3.0.1'		# Used to protect secrets and install info
  pod 'Facade',                   '~> 1.1.1'	    # Convenience methods for frame based layout
  pod 'SwiftyBeaver'
  pod 'Bugsnag'                                     # Crash reporting
  pod 'Firebase/RemoteConfig'
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
