# Triple Play Pay - iOS MagTek SDK

A library for integrating with MagTek devices from Triple Play Pay

## Using with Cocoa Pods
To use this library in your cocoapods project, place this in your Podfile
```sh
# make sure to target iOS 12.4 at a minimum
platform :ios, '12.4'

target 'MyApp' do
    # make sure to include 'use_frameworks!'
    use_frameworks!

    # add this library to your dependencies
    pod 'TPP-MagTekSDK'
end
```

## Building locally
Navigate into the source folder and run the build script
```sh
cd ./MagTekSDK
sh ./build-xcframework.sh
```
After that, you can look under the newly created `Build` folder to grab the xcframework.

## Documentation
Go [here](Docs/magtek-card-reader.md)
