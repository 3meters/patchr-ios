# Open source
source 'https://github.com/CocoaPods/Specs.git'

plugin 'cocoapods-keys', {
  :project => "Teeny",
  :targets => ["Teeny","Teeny-Dev"],
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
    pod 'AIFlatSwitch',             '1.0.2'
    pod 'AlertOnboarding',          '2.0'
    pod 'AMScrollingNavbar',        '4.0.1'
    pod 'BEMCheckBox',              '1.4.0'
    pod 'Branch',                   '0.14.12'     # Url routing and deep linking
    pod 'ChameleonFramework/Swift', :git => 'https://github.com/ViccAlexander/Chameleon.git'
    pod 'CocoaLumberjack/Swift',    '3.0.0'
    pod 'CLTokenInputView',         '2.3.0'
    pod 'DLRadioButton',            '1.4.9'
    pod 'Emoji-swift',              '0.1.0'
    pod 'Facade',                   '1.1.1'	    # Convenience methods for frame based layout
    pod 'Firebase/Auth',            '4.1.0'
    pod 'Firebase/Core',            '4.1.0'
    pod 'Firebase/Crash',           '4.1.0'
    pod 'Firebase/Database',        '4.1.0'
    pod 'Firebase/Messaging',       '4.1.0'
    pod 'Firebase/Storage',         '4.1.0'
    pod 'FirebaseUI/Database',      '4.1.1'
    pod 'IDMPhotoBrowser',          :path => '~/code/IDMPhotoBrowser'
    pod 'Localize-Swift',           '1.7.0'
    pod 'MBProgressHUD',            '0.9.2'
    pod 'NextGrowingTextView',      '1.2.2'
    pod 'NHBalancedFlowLayout',     '0.2'
    pod 'Pastel',                   '0.3.0'
    pod 'PBWebViewController',      '0.5.0'		# Used to show show web content for terms/policy/licensing
    pod 'PhoneNumberKit',           '2.0.0'
    pod 'pop',                      '1.0.9'		# Animation library
    pod 'PopupDialog',              '0.6.2'
    pod 'SDWebImage',               '4.0.0'
    pod 'SkyFloatingLabelTextField',:git => 'https://github.com/Skyscanner/SkyFloatingLabelTextField/'
    pod 'SlackTextViewController',  :git => 'https://github.com/slackhq/SlackTextViewController.git'
    pod 'STPopup',                  '1.8.3'
    pod 'TTTAttributedLabel',       '2.0.0'
    pod 'UIDevice-Hardware',        '0.1.8'		# Convenience for determining system version and model identifier
    pod 'VTAcknowledgementsViewController','1.2.1'
end

target 'Teeny' do
    shared_pods
end

target 'Teeny-Dev' do
    shared_pods
end

plugin 'cocoapods-no-dev-schemes'

post_install do |installer|
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods-Teeny/Pods-Teeny-acknowledgements.plist', 'App/Pods-acknowledgements.plist', :remove_destination => true)
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.0'
        end
    end
end

# CreativeSDKCore and Image frameworks are on version 0.12.2127.02
