#!/bin/bash
DMG_SOURCES="./ImageShack iPhoto Plugin.pkg"
DMG_IMAGE="./ImageShack iPhoto Plugin.dmg"
DMG_NAME="ImageShack iPhoto Plugin"
HDIUTIL=/usr/bin/hdiutil

DMG_DIR=$DMG_IMAGE.src

if test -e "$DMG_DIR"; then
	echo "Directory $DMG_DIR already exists. Please delete it manually." >&2
	exit 1
fi

#echo "Cleaning up"
#rm -f "$DMG_IMAGE" || exit 1
mkdir "$DMG_DIR" || exit 1

echo "Copying data into temporary directory"
for src in "$DMG_SOURCES"; do
	echo $src
	cp -r "$src" "$DMG_DIR" || exit 1
done

echo "Creating image"
$HDIUTIL create -quiet -srcfolder "$DMG_DIR" -format UDZO -volname "$DMG_NAME" -ov "$DMG_IMAGE" || exit 1
rm -rf "$DMG_DIR" || exit 1