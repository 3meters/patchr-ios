#!/bin/sh

xcodebuild -workspace ./Patchr.xcworkspace \
	-scheme "PatchrUITests" \
	-sdk iphonesimulator \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2'
	test