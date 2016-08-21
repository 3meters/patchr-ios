# Open source
source 'https://github.com/CocoaPods/Specs.git'

plugin 'cocoapods-keys', {
  :project => "Patchr",
  :targets => ["Patchr", "PatchrShare"],
  :keys => [
    "BugsnagKey",
    "SegmentKey",
    "BingAccessKey",
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
  pod 'SDWebImage',                 '~> 3.7.2'
  pod 'Lockbox'										# Used to protect secrets and install info
  pod 'AWSS3', 					    '~> 2.4'
  pod 'AFNetworking',				'~> 2.6'
  pod 'AFNetworkActivityLogger',	'~> 2.0'
  pod 'PBWebViewController',		'~> 0.5'			# Used to show show web content for terms/policy/licensing
  pod 'MBProgressHUD',			    '~> 0.9.1'
  pod 'DLRadioButton'
  pod 'DynamicButton',			    '~> 2.1.0'
  pod 'NHBalancedFlowLayout',		'~> 0.2'
  pod 'UIDevice-Hardware'								# Convenience for determining system version and model identifier
  pod 'pop', '~> 1.0'									# Animation library
  pod 'IDMPhotoBrowser',			:path => '~/code/IDMPhotoBrowser'
  pod 'TWMessageBarManager',		'~> 1.8'			# In-app notifications
  pod 'Facade'										# Convenience methods for frame based layout
  pod 'THContactPicker',			'~> 1.2'			# Used in message edit
  pod 'FBSDKCoreKit',				'~> 4.11.0'
  pod 'FBSDKLoginKit',			    '~> 4.11.0'
  pod 'FBSDKShareKit',			    '~> 4.11.0'
  pod 'DateTools'
  pod 'Parse'											# Push notifications
  pod 'iRate'
  pod 'CocoaLumberjack/Swift'
  pod 'Analytics',				    '~> 3.0'			# Segment pipeline
  pod 'Google/Analytics'
  pod 'Branch'										# Url routing and deep linking
  pod 'Bugsnag'										# Crash reporting
end

target 'Patchr' do
  core_pods
end

target 'PatchrTests' do
  core_pods
  pod 'Quick',					    '~> 0.9.1'
  pod 'Nimble'
  pod 'KIF/IdentifierTests',		'~> 3.0', :configurations => ['Debug']
end

target 'PatchrShare' do
  pod 'SDWebImage',				    '~> 3.7.2'
  pod 'AWSS3'
  pod 'Lockbox'										# Used to protect secrets and install info
  pod 'Facade'										# Convenience methods for frame based layout
  pod 'CocoaLumberjack/Swift'
  pod 'Bugsnag'
end

plugin 'cocoapods-no-dev-schemes'

# CreativeSDKCore and Image frameworks are on version 0.12.2127.02
