#!/bin/sh

# Won't run xcode ui tests without fix from xctool. https://github.com/facebook/xctool/issues/534
# xctool/xctool.sh \
#	-workspace Patchr.xcworkspace \
#	-scheme Patchr \
#	-sdk iphonesimulator \
#	test

# xcodebuild \
#	-workspace Patchr.xcworkspace \
#	-scheme PatchrUITests \
#	-sdk iphonesimulator \
#	-destination 'platform=iOS Simulator,name=iPhone 6 Plus Jay,OS=9.2' \
#	test

scan \
	--workspace Patchr.xcworkspace \
	--scheme PatchrUITests \
	--sdk iphonesimulator \
	--output_directory ./test_output \
	--device 'iPhone 6 Plus Jay'
