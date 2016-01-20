#!/bin/sh

xctool 	-workspace Patchr.xcworkspace \
		-scheme Patchr \
		-sdk iphonesimulator \
		build
