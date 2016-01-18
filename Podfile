# Open source
source 'https://github.com/CocoaPods/Specs.git'

plugin 'cocoapods-keys', {
	:project => "Patchr",
	:targets => ["Patchr", "PatchrShare"],
	:keys => [
		"BingAccessKey",
		"CreativeSdkClientId",
		"CreativeSdkClientSecret",
		"AwsS3Key",
		"AwsS3Secret",
		"ParseApplicationId",
		"ParseApplicationKey",
		"FabricApiKey",
		"BranchKey",
		"ProxibaseSecret",
		"FacebookToken"
	]
}

platform :ios, '8.0'
inhibit_all_warnings!

target 'Patchr' do
	
	pod 'AFNetworking',				'~> 2.6'
	pod 'AFNetworkActivityLogger',	'~> 2.0'
	pod 'AWSS3'
	pod 'PBWebViewController',		'~> 0.3'			# Used to show show web content for terms/policy/licensing
	pod 'MBProgressHUD',			'~> 0.9.1'
	pod 'SDWebImage',				'~> 3.7.2'
	pod 'DLRadioButton'
	pod 'UIDevice-Hardware'								# Convenience for determining system version and model identifier
	pod 'Lockbox'										# Used to protect secrets and install info
	pod 'Branch'										# Url routing and deep linking
	pod 'pop', '~> 1.0'									# Animation library
	pod 'AirPhotoBrowser',			:path => '~/code/AirPhotoBrowser'
	pod 'TWMessageBarManager',		'~> 1.8'			# In-app notifications
	pod 'Facade'										# Convenience methods for frame based layout
	pod 'Google/Analytics'
	pod 'Fabric'
	pod 'Crashlytics'
	pod 'THContactPicker',			'~> 1.2'
	pod 'FBSDKCoreKit',				'~> 4.9.0'
	pod 'FBSDKLoginKit',			'~> 4.9.0'
	pod 'FBSDKShareKit',			'~> 4.9.0'
	pod 'DateTools'

end

target 'PatchrUITests' do

	pod 'Lockbox'

end

target 'PatchrShare' do

	pod 'SDWebImage',				'~> 3.7.2'
	pod 'AWSS3'
	pod 'Lockbox'

end

# CreativeSDKCore and Image frameworks are on version 0.12.2127.02

