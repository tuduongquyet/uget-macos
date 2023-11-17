#!/bin/sh

rm -rf ./uGet.app
iconutil -c icns ./iconbuilder.iconset --output uGet.icns
~/.new_local/bin/gtk-mac-bundler uget.bundle
cp -R Papirus Papirus-Dark ./uGet.app/Contents/Resources/share/icons

# Pull resources from uget-integrator
mkdir -p ./uGet.app/Contents/Resources/NativeMessagingHosts
curl -sSL https://github.com/tuduongquyet/uget-integrator/raw/master/bin/uget-integrator-mac -o ./uGet.app/Contents/macOS/uget-integrator || exit 1
chmod +x ./uGet.app/Contents/macOS/uget-integrator
curl -sSL https://github.com/tuduongquyet/uget-integrator/raw/master/conf/com.ugetdm.chrome.mac.json -o ./uGet.app/Contents/Resources/NativeMessagingHosts/com.ugetdm.chrome.json || exit 1
curl -sSL https://github.com/tuduongquyet/uget-integrator/raw/master/conf/com.ugetdm.firefox.mac.json -o ./uGet.app/Contents/Resources/NativeMessagingHosts/com.ugetdm.firefox.json || exit 1
