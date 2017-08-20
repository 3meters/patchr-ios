# Open source
source 'https://github.com/CocoaPods/Specs.git'

plugin 'cocoapods-keys', {
  :project => "Patchr",
  :targets => ["Patchr","Patchr-Dev"],
  :keys => [
    "BingSubscriptionKey",      # p1
    "CreativeSdkClientSecret",  # p2
    "BranchKey"                 # p3
  ]
}

platform :ios, '9.0'
inhibit_all_warnings!
use_frameworks!

def shared_pods
    pod 'AFNetworkActivityLogger',  '2.0.4'
    pod 'AFNetworking',             '2.6.3'
    pod 'AlertOnboarding',          '1.9'
    pod 'BEMCheckBox',              '1.4.0'
    pod 'Branch',                   '0.14.12'     # Url routing and deep linking
    pod 'ChameleonFramework/Swift', :git => 'https://github.com/ViccAlexander/Chameleon.git'
    pod 'CocoaLumberjack/Swift',    '3.0.0'
    pod 'CLTokenInputView',         '2.3.0'
    pod 'DateTools',                :git => 'https://github.com/MatthewYork/DateTools', :branch => 'swift'
    pod 'DLRadioButton',            '1.4.9'
    pod 'Emoji-swift',              '0.1.0'
    pod 'Facade',                   '1.1.1'	    # Convenience methods for frame based layout
    pod 'Firebase/Auth',            '4.0.4'
    pod 'Firebase/Core',            '4.0.4'
    pod 'Firebase/Crash',           '4.0.4'
    pod 'Firebase/Database',        '4.0.4'
    pod 'Firebase/Messaging',       '4.0.4'
    pod 'Firebase/Storage',         '4.0.4'
    pod 'FirebaseUI/Database',      '4.1.1'
    pod 'iRate',                    '1.11.6'
    pod 'IDMPhotoBrowser',          :path => '~/code/IDMPhotoBrowser'
    pod 'MBProgressHUD',            '0.9.2'
    pod 'NHBalancedFlowLayout',     '0.2'
    pod 'PBWebViewController',      '0.5.0'		# Used to show show web content for terms/policy/licensing
    pod 'PhoneNumberKit',           '1.0.1'
    pod 'pop',                      '1.0.9'		# Animation library
    pod 'PopupDialog',              '0.5.3'
    pod 'ReachabilitySwift',        '3'
    pod 'SDWebImage/GIF',           '4.0.0'
    pod 'SkyFloatingLabelTextField','2.0.0'
    pod 'SlackTextViewController',  :path => '~/code/SlackTextViewController'
    pod 'STPopup',                  '1.8.2'
    pod 'TTTAttributedLabel',       '2.0.0'
    pod 'UIDevice-Hardware',        '0.1.8'		# Convenience for determining system version and model identifier
    pod 'VTAcknowledgementsViewController','1.2.1'
end

target 'Patchr' do
    shared_pods
end

target 'Patchr-Dev' do
    shared_pods
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
