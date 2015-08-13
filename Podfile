
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.1'

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

pod 'AFNetworking', '~> 2.5'
pod 'AFNetworkActivityLogger', '~> 2.0'
pod 'AWSS3', '~> 2.2.0'
pod 'RMCoreDataStack'
pod 'PBWebViewController', '~> 0.3'  # Used to show show web content for terms/policy/licensing
pod 'MBProgressHUD', '~> 0.9.1'
pod 'SDWebImage', '~> 3.7.2'
pod 'UIDevice-Hardware'
pod 'Lockbox'                       # Used to protect install info
pod 'UIScrollView-InfiniteScroll'
pod 'libPhoneNumber-iOS', '~> 0.7'
pod 'Branch'
pod 'pop', :git => 'https://github.com/facebook/pop.git'
pod 'AirPhotoBrowser', :path => '~/code/AirPhotoBrowser'
pod 'AirContactPicker', :path => '~/code/AirContactPicker'
pod 'TWMessageBarManager'
pod 'Google/Analytics', '~> 1.0.0'

end

target 'PatchrShare' do

pod 'SDWebImage', '~> 3.7.2'
pod 'AWSS3', '~> 2.2.0'

end

# link_with ['Patchr', 'PatchrShare']