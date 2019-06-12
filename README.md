# Defold Deployer
Unique build && deploy script for mobile projects (Android, iOS) for Defold Engine

## Features:
- Single deployment script on all Defold mobile projects
- One command to build, deploy and read logs from the mobile
- Custom settings on project (provisions, bob version, etc)
- Save your time on preparing debug & release builds
- Nice naming builds to save history of product versions

## Install:
*ios-deloy*: https://github.com/ios-control/ios-deploy
*adb*: https://developer.android.com/studio/releases/platform-tools
*java*: https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html

## Usage:
`bash deployer.sh [a][i][r][b][d]`
`a` - add target platform Android
`i` - add target platform iOS
`r` - set build mode to Release
`b` - build project (game bundle will be in ./dist folder)
`d` - deploy bundle to connected device
- it will deploy && run bundle on Android
- it will only deploy bundle on iOS (for now)

Bundle files will be located at *./dist/bundle*
With name {ProjectName}_{Version}_{BuildMode}.[apk|ipa]

##	Example:
`./deployer.sh abd` - build, deploy and run Android bundle
`./deployer.sh ird` - build and deploy iOS release bundle
`./deployer.sh aibr` - build Android and iOS release bundles

You can pass params in any order you want, for example:
`./deployer.sh riba` - same behaviour as aibr

## Custom parameters:
You can setup custom parameters (like provisions, keys and certificate, bob version)
Deployer params can be overrided with ./custom_deployer script
If this file exist, it will run inside this script

Just declare new global vars inside custom_deployer like this:
```bash
ios_prov_dev=./provisions/dev.mobileprovision
ios_identity_dev="AAABBCUSTOM"
bob_sha="155:838cecd7a26c932e6be73421d98e51ba12f1d462"
```

## Author
Insality
