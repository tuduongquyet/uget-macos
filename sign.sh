#!/bin/sh

sign() {
	codesign -s "$2" --entitlements uget.entitlements --deep --force --strict=all --options runtime -vvv "$1"
}
export -f sign

sign "./uGet.app/Contents/MacOS/uget-bin" "$SIGN_CERTIFICATE"
find ./uGet.app \( -name "*.dylib" -or -name "*.so" \) -exec sh -c 'sign "$0" "$SIGN_CERTIFICATE"' {} \;
sign "./uGet.app" "$SIGN_CERTIFICATE"
