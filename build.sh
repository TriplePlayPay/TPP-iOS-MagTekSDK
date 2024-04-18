#!/bin/sh

src=MagTekSDK
lib=MagTekSDK.xcframework

echo "Building the XCFramework..."
cd ./$src && sh build-xcframework.sh && cd ..

echo "Cleaning..."
rm -rf ./$lib

echo "Copying files..."
mv ./$src/Build/$lib .

echo "Stripping debug symbols"
ex '+g/<key>DebugSymbolsPath<\/key>/d' -cwq ./$lib/Info.plist
ex '+g/<string>dSYMs<\/string>/d' -cwq ./$lib/Info.plist
