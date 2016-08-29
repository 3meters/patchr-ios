# Open source
source 'https://github.com/CocoaPods/Specs.git'

plugin 'cocoapods-keys', {
  :project => "Patchr",
  :targets => ["Patchr", "PatchrShare"],
  :keys => [
    "BugsnagKey",
    "SegmentKey",
    "BingAccessKey",
    "BingSubscriptionKey",
    "CreativeSdkClientId",
    "CreativeSdkClientSecret",
    "AwsS3Key",
    "AwsS3Secret",
    "ParseApplicationId",
    "ParseApplicationKey",
    "BranchKey",
    "ProxibaseSecret",
    "FacebookToken"
  ]
}

platform :ios, '8.0'
inhibit_all_warnings!
use_frameworks!

def core_pods
  pod 'IDMPhotoBrowser', :path => '~/code/IDMPhotoBrowser'
  pod 'SDWebImage',               '~> 3.8.1'
  pod 'Lockbox',                  '~> 3.0.1'		# Used to protect secrets and install info
  pod 'AWSS3',                    '~> 2.4'
  pod 'AFNetworking',             '~> 2.6'
  pod 'AFNetworkActivityLogger',  '~> 2.0'
  pod 'PBWebViewController',      '~> 0.5'		# Used to show show web content for terms/policy/licensing
  pod 'MBProgressHUD',            '~> 0.9.1'
  pod 'DLRadioButton',            '~> 1.4.9'
  pod 'DynamicButton',            '~> 2.1.0'
  pod 'NHBalancedFlowLayout',     '~> 0.2'
  pod 'UIDevice-Hardware',        '~> 0.1.7'		# Convenience for determining system version and model identifier
  pod 'pop',                      '~> 1.0'		# Animation library
  pod 'TWMessageBarManager',      '~> 1.8'		# In-app notifications
  pod 'Facade',                   '~> 1.1.1'	    # Convenience methods for frame based layout
  pod 'THContactPicker',          '~> 1.2'		# Used in message edit
  pod 'FBSDKCoreKit',             '~> 4.14.0'
  pod 'FBSDKLoginKit',            '~> 4.14.0'
  pod 'FBSDKShareKit',            '~> 4.14.0'
  pod 'DateTools',                '~> 1.7.0'
  pod 'iRate',                    '~> 1.11.6'
  pod 'CocoaLumberjack/Swift',    '~> 2.3.0'
  pod 'Google/Analytics'
  pod 'Branch',                   '~> 0.12.5'     # Url routing and deep linking
  pod 'Bugsnag',                  '~> 5.4.2'      # Crash reporting
  pod 'OneSignal',                '~> 2.0.10'
  pod 'RxSwift',                  '~> 2.6.0'
end

target 'Patchr' do
  core_pods
end

target 'PatchrTests' do
  core_pods
  pod 'Quick',                    '~> 0.9.3'
  pod 'Nimble',                   '~> 4.1.0'
  pod 'KIF/IdentifierTests',      '~> 3.3.2', :configurations => ['Debug']
end

target 'PatchrShare' do
  pod 'SDWebImage',               '~> 3.8.1'
  pod 'AWSS3',                    '~> 2.4'
  pod 'Lockbox',                  '~> 3.0.1'		# Used to protect secrets and install info
  pod 'Facade',                   '~> 1.1.1'	    # Convenience methods for frame based layout
  pod 'CocoaLumberjack/Swift',    '~> 2.3.0'
  pod 'Bugsnag',                  '~> 5.4.2'      # Crash reporting
end

plugin 'cocoapods-no-dev-schemes'

# CreativeSDKCore and Image frameworks are on version 0.12.2127.02
