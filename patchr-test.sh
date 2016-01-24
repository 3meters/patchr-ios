#!/bin/sh
# Must be device type not device name, use xcrun simctl list
xctool	-workspace Patchr.xcworkspace \
		-scheme Patchr \
		-sdk iphonesimulator \
		-destination 'name=iPhone 6 Plus' \
		run-tests -resetSimulator

# xcodebuild \
#	-workspace Patchr.xcworkspace \
#	-scheme PatchrUITests \
#	-sdk iphonesimulator \
#	-destination 'platform=iOS Simulator,name=iPhone 6 Plus Jay,OS=9.2' \
#	test

#scan \
#	--workspace Patchr.xcworkspace \
#	--scheme Patchr \
#	--sdk iphonesimulator \
#	--output_directory ./test_output \
#	--device 'iPhone 6 Plus'
