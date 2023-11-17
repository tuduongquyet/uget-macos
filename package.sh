#!/bin/sh

VERSION="2.2.3"

FILE_TYPE=`file uGet.app/Contents/MacOS/uGet`
if [[ "$FILE_TYPE" == *"arm64"* ]]; then
	PKGNAME="uget-${VERSION}_osx_arm64.pkg"
else
	PKGNAME="uget-${VERSION}_osx_x86_64.pkg"
fi
rm -rf ./BUILD
mkdir -p ./BUILD/Applications
cp -R uGet.app ./BUILD/Applications
pkgbuild --identifier "com.ugetdm.uget" --version "2.2.3" --scripts ./scripts --root ./BUILD ./${PKGNAME}
