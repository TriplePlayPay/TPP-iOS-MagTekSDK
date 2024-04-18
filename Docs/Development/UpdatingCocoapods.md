# Staging the project for release on cocoapods.org
First, build the most recent xcframework by running `sh ./build.sh` in the root directory. This will build the framework, move it out of the build folder and into the root directory, then modify the Info.plist file for distribution. Once that is complete, you must update the git repository
- NOTE: make sure to update the podspec file with the proper tag version. You need to change the tag in `spec.source` as well.
```sh
git commit -am 'updated build' # commit all changes
# make sure to add a new tag before releasing to cocoapods.org
git tag -a '<version>' # version must be x.x.x
git push --tags # push a new tag to the main branch
git push # updates the main git branch with changes
```
## Cocoapods Account
Once the git repository is updated remotely, you need to make sure to sign into your cocoapods account. You can log in OR create a new account by using the following command. Once you create an account / log in, you likely wont need to sign in again on the same device.
```sh
pod trunk register user@example.com 'Display Name' --description='Dev Laptop'
```
If you are creating a new account please reach out to `parker@tripleplaypay.com` so that he may add you as an owner.
## Publish
After ensuring you're logged in, just run this command to publish the repo
```sh
pod trunk push TPP-MagTekSDK.podspec # make sure tag version matches git tag
```
