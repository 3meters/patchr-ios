#!/bin/sh

xctool	-workspace Patchr.xcworkspace \
		-scheme Patchr \
		-sdk iphonesimulator \
		-destination 'name=iPhone 6 Plus' \
		build
