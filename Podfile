
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '8.0'

plugin 'cocoapods-keys', {
    :project => "Patchr",
    :keys => [
    "BingAccessKey",
    "CreativeSdkClientId",
    "CreativeSdkClientSecret",
    "AwsS3Key",
    "AwsS3Secret",
    "ParseApplicationId",
    "ParseApplicationKey",
    "FabricApiKey",
    "BranchKey"
    ]}

target 'Patchr' do

pod 'AFNetworking', '~> 2.6'
pod 'AFNetworkActivityLogger', '~> 2.0'
pod 'AWSS3', '~> 2.2.0'
pod 'PBWebViewController', '~> 0.3'     # Used to show show web content for terms/policy/licensing
pod 'MBProgressHUD', '~> 0.9.1'
pod 'SDWebImage', '~> 3.7.2'
pod 'UIDevice-Hardware'                 # Convenience for determining system version and model identifier
pod 'Lockbox'                           # Used to protect install info
pod 'libPhoneNumber-iOS', '~> 0.7'      # Used to parse and format phone# for places
pod 'Branch'							# Url routing and deep linking
pod 'pop', '~> 1.0'						# Animation library
pod 'AirPhotoBrowser', :path => '~/code/AirPhotoBrowser'
pod 'AirContactPicker', :path => '~/code/AirContactPicker'
pod 'TWMessageBarManager'				# In-app notifications
pod 'Harpy'								# App update alerts
pod 'Facade'							# Convenience methods for frame based layout
pod 'Google/Analytics', '~> 1.0.0'
pod 'Fabric'
pod 'Crashlytics'

end

target 'PatchrShare' do

pod 'SDWebImage', '~> 3.7.2'
pod 'AWSS3', '~> 2.2.0'

end

# link_with ['Patchr', 'PatchrShare']