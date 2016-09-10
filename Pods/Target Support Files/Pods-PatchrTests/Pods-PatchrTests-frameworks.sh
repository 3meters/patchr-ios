#!/bin/sh
set -e

echo "mkdir -p ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
mkdir -p "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

SWIFT_STDLIB_PATH="${DT_TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"

install_framework()
{
  if [ -r "${BUILT_PRODUCTS_DIR}/$1" ]; then
    local source="${BUILT_PRODUCTS_DIR}/$1"
  elif [ -r "${BUILT_PRODUCTS_DIR}/$(basename "$1")" ]; then
    local source="${BUILT_PRODUCTS_DIR}/$(basename "$1")"
  elif [ -r "$1" ]; then
    local source="$1"
  fi

  local destination="${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

  if [ -L "${source}" ]; then
      echo "Symlinked..."
      source="$(readlink "${source}")"
  fi

  # use filter instead of exclude so missing patterns dont' throw errors
  echo "rsync -av --filter \"- CVS/\" --filter \"- .svn/\" --filter \"- .git/\" --filter \"- .hg/\" --filter \"- Headers\" --filter \"- PrivateHeaders\" --filter \"- Modules\" \"${source}\" \"${destination}\""
  rsync -av --filter "- CVS/" --filter "- .svn/" --filter "- .git/" --filter "- .hg/" --filter "- Headers" --filter "- PrivateHeaders" --filter "- Modules" "${source}" "${destination}"

  local basename
  basename="$(basename -s .framework "$1")"
  binary="${destination}/${basename}.framework/${basename}"
  if ! [ -r "$binary" ]; then
    binary="${destination}/${basename}"
  fi

  # Strip invalid architectures so "fat" simulator / device frameworks work on device
  if [[ "$(file "$binary")" == *"dynamically linked shared library"* ]]; then
    strip_invalid_archs "$binary"
  fi

  # Resign the code if required by the build settings to avoid unstable apps
  code_sign_if_enabled "${destination}/$(basename "$1")"

  # Embed linked Swift runtime libraries. No longer necessary as of Xcode 7.
  if [ "${XCODE_VERSION_MAJOR}" -lt 7 ]; then
    local swift_runtime_libs
    swift_runtime_libs=$(xcrun otool -LX "$binary" | grep --color=never @rpath/libswift | sed -E s/@rpath\\/\(.+dylib\).*/\\1/g | uniq -u  && exit ${PIPESTATUS[0]})
    for lib in $swift_runtime_libs; do
      echo "rsync -auv \"${SWIFT_STDLIB_PATH}/${lib}\" \"${destination}\""
      rsync -auv "${SWIFT_STDLIB_PATH}/${lib}" "${destination}"
      code_sign_if_enabled "${destination}/${lib}"
    done
  fi
}

# Signs a framework with the provided identity
code_sign_if_enabled() {
  if [ -n "${EXPANDED_CODE_SIGN_IDENTITY}" -a "${CODE_SIGNING_REQUIRED}" != "NO" -a "${CODE_SIGNING_ALLOWED}" != "NO" ]; then
    # Use the current code_sign_identitiy
    echo "Code Signing $1 with Identity ${EXPANDED_CODE_SIGN_IDENTITY_NAME}"
    echo "/usr/bin/codesign --force --sign ${EXPANDED_CODE_SIGN_IDENTITY} --preserve-metadata=identifier,entitlements \"$1\""
    /usr/bin/codesign --force --sign ${EXPANDED_CODE_SIGN_IDENTITY} --preserve-metadata=identifier,entitlements "$1"
  fi
}

# Strip invalid architectures
strip_invalid_archs() {
  binary="$1"
  # Get architectures for current file
  archs="$(lipo -info "$binary" | rev | cut -d ':' -f1 | rev)"
  stripped=""
  for arch in $archs; do
    if ! [[ "${VALID_ARCHS}" == *"$arch"* ]]; then
      # Strip non-valid architectures in-place
      lipo -remove "$arch" -output "$binary" "$binary" || exit 1
      stripped="$stripped $arch"
    fi
  done
  if [[ "$stripped" ]]; then
    echo "Stripped $binary of architectures:$stripped"
  fi
}


if [[ "$CONFIGURATION" == "Debug" ]]; then
  install_framework "Pods-PatchrTests/AFNetworkActivityLogger.framework"
  install_framework "Pods-PatchrTests/AFNetworking.framework"
  install_framework "Pods-PatchrTests/AWSCore.framework"
  install_framework "Pods-PatchrTests/AWSS3.framework"
  install_framework "Pods-PatchrTests/Bolts.framework"
  install_framework "Pods-PatchrTests/Branch.framework"
  install_framework "Pods-PatchrTests/Bugsnag.framework"
  install_framework "Pods-PatchrTests/CocoaLumberjack.framework"
  install_framework "Pods-PatchrTests/DACircularProgress.framework"
  install_framework "Pods-PatchrTests/DLRadioButton.framework"
  install_framework "Pods-PatchrTests/DateTools.framework"
  install_framework "Pods-PatchrTests/DynamicButton.framework"
  install_framework "Pods-PatchrTests/FBSDKCoreKit.framework"
  install_framework "Pods-PatchrTests/FBSDKLoginKit.framework"
  install_framework "Pods-PatchrTests/FBSDKShareKit.framework"
  install_framework "Pods-PatchrTests/Facade.framework"
  install_framework "Pods-PatchrTests/FontAwesome_swift.framework"
  install_framework "Pods-PatchrTests/IDMPhotoBrowser.framework"
  install_framework "Pods-PatchrTests/KSCrash.framework"
  install_framework "Pods-PatchrTests/Lockbox.framework"
  install_framework "Pods-PatchrTests/MBProgressHUD.framework"
  install_framework "Pods-PatchrTests/NHBalancedFlowLayout.framework"
  install_framework "Pods-PatchrTests/PBWebViewController.framework"
  install_framework "Pods-PatchrTests/RxSwift.framework"
  install_framework "Pods-PatchrTests/SDWebImage.framework"
  install_framework "Pods-PatchrTests/SlideMenuControllerSwift.framework"
  install_framework "Pods-PatchrTests/THContactPicker.framework"
  install_framework "Pods-PatchrTests/TWMessageBarManager.framework"
  install_framework "Pods-PatchrTests/UIDevice_Hardware.framework"
  install_framework "Pods-PatchrTests/iRate.framework"
  install_framework "Pods-PatchrTests/pop.framework"
  install_framework "Pods-PatchrTests/KIF.framework"
  install_framework "Pods-PatchrTests/Nimble.framework"
  install_framework "Pods-PatchrTests/Quick.framework"
fi
if [[ "$CONFIGURATION" == "Release" ]]; then
  install_framework "Pods-PatchrTests/AFNetworkActivityLogger.framework"
  install_framework "Pods-PatchrTests/AFNetworking.framework"
  install_framework "Pods-PatchrTests/AWSCore.framework"
  install_framework "Pods-PatchrTests/AWSS3.framework"
  install_framework "Pods-PatchrTests/Bolts.framework"
  install_framework "Pods-PatchrTests/Branch.framework"
  install_framework "Pods-PatchrTests/Bugsnag.framework"
  install_framework "Pods-PatchrTests/CocoaLumberjack.framework"
  install_framework "Pods-PatchrTests/DACircularProgress.framework"
  install_framework "Pods-PatchrTests/DLRadioButton.framework"
  install_framework "Pods-PatchrTests/DateTools.framework"
  install_framework "Pods-PatchrTests/DynamicButton.framework"
  install_framework "Pods-PatchrTests/FBSDKCoreKit.framework"
  install_framework "Pods-PatchrTests/FBSDKLoginKit.framework"
  install_framework "Pods-PatchrTests/FBSDKShareKit.framework"
  install_framework "Pods-PatchrTests/Facade.framework"
  install_framework "Pods-PatchrTests/FontAwesome_swift.framework"
  install_framework "Pods-PatchrTests/IDMPhotoBrowser.framework"
  install_framework "Pods-PatchrTests/KSCrash.framework"
  install_framework "Pods-PatchrTests/Lockbox.framework"
  install_framework "Pods-PatchrTests/MBProgressHUD.framework"
  install_framework "Pods-PatchrTests/NHBalancedFlowLayout.framework"
  install_framework "Pods-PatchrTests/PBWebViewController.framework"
  install_framework "Pods-PatchrTests/RxSwift.framework"
  install_framework "Pods-PatchrTests/SDWebImage.framework"
  install_framework "Pods-PatchrTests/SlideMenuControllerSwift.framework"
  install_framework "Pods-PatchrTests/THContactPicker.framework"
  install_framework "Pods-PatchrTests/TWMessageBarManager.framework"
  install_framework "Pods-PatchrTests/UIDevice_Hardware.framework"
  install_framework "Pods-PatchrTests/iRate.framework"
  install_framework "Pods-PatchrTests/pop.framework"
  install_framework "Pods-PatchrTests/Nimble.framework"
  install_framework "Pods-PatchrTests/Quick.framework"
fi
if [[ "$CONFIGURATION" == "Adhoc" ]]; then
  install_framework "Pods-PatchrTests/AFNetworkActivityLogger.framework"
  install_framework "Pods-PatchrTests/AFNetworking.framework"
  install_framework "Pods-PatchrTests/AWSCore.framework"
  install_framework "Pods-PatchrTests/AWSS3.framework"
  install_framework "Pods-PatchrTests/Bolts.framework"
  install_framework "Pods-PatchrTests/Branch.framework"
  install_framework "Pods-PatchrTests/Bugsnag.framework"
  install_framework "Pods-PatchrTests/CocoaLumberjack.framework"
  install_framework "Pods-PatchrTests/DACircularProgress.framework"
  install_framework "Pods-PatchrTests/DLRadioButton.framework"
  install_framework "Pods-PatchrTests/DateTools.framework"
  install_framework "Pods-PatchrTests/DynamicButton.framework"
  install_framework "Pods-PatchrTests/FBSDKCoreKit.framework"
  install_framework "Pods-PatchrTests/FBSDKLoginKit.framework"
  install_framework "Pods-PatchrTests/FBSDKShareKit.framework"
  install_framework "Pods-PatchrTests/Facade.framework"
  install_framework "Pods-PatchrTests/FontAwesome_swift.framework"
  install_framework "Pods-PatchrTests/IDMPhotoBrowser.framework"
  install_framework "Pods-PatchrTests/KSCrash.framework"
  install_framework "Pods-PatchrTests/Lockbox.framework"
  install_framework "Pods-PatchrTests/MBProgressHUD.framework"
  install_framework "Pods-PatchrTests/NHBalancedFlowLayout.framework"
  install_framework "Pods-PatchrTests/PBWebViewController.framework"
  install_framework "Pods-PatchrTests/RxSwift.framework"
  install_framework "Pods-PatchrTests/SDWebImage.framework"
  install_framework "Pods-PatchrTests/SlideMenuControllerSwift.framework"
  install_framework "Pods-PatchrTests/THContactPicker.framework"
  install_framework "Pods-PatchrTests/TWMessageBarManager.framework"
  install_framework "Pods-PatchrTests/UIDevice_Hardware.framework"
  install_framework "Pods-PatchrTests/iRate.framework"
  install_framework "Pods-PatchrTests/pop.framework"
  install_framework "Pods-PatchrTests/Nimble.framework"
  install_framework "Pods-PatchrTests/Quick.framework"
fi
