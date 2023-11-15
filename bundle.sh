#!/bin/sh

rm -rf ./uGet.app
iconutil -c icns ./iconbuilder.iconset --output uGet.icns
~/.new_local/bin/gtk-mac-bundler geany.bundle
cp -R Papirus Papirus-Dark ./uGet.app/Contents/Resources/share/icons
