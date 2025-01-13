#!/bin/zsh
xcodebuild \
  -project LocsUtil.xcodeproj \
  -scheme LocsUtil \
  -configuration Release \
  -sdk macosx \
  archive -archivePath $TMPDIR/LocsUtil.xcarchive \

if [ $? -ne 0 ]; then
    echo "Build failed"
    exit 1
fi

mkdir bin
cp $TMPDIR/LocsUtil.xcarchive/Products/usr/local/bin/locsutil bin/locsutil
rm -rf $TMPDIR/LocsUtil.xcarchive
