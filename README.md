# Defold Deployer
Unique build && deploy script for mobile projects (Android, iOS) for Defold Engine

## Features
- Single deployment script on all Defold mobile projects
- One command to build, deploy and read logs from the mobile
- Custom settings on project (provisions, bob version, etc)
- Save your time on preparing debug & release builds
- Nice naming builds to save history of product versions
- Auto *bob.jar* downloading. Flag **use_latest_bob** for using always last version of defold

## Install
For bob build tool you need to install java 1.8

For ios deploy by cable you need to install:
*ios-deloy*: https://github.com/ios-control/ios-deploy

For android deploy and read logs you need to install:
*adb*: https://developer.android.com/studio/releases/platform-tools


## Setup
I recommend place `deployer.sh` in your path with name `deployer`, chmod +x it and call it in your project folder like:
`deployer abd`

Override global settings for your projects inside `deployer` scripts. See **custom parameters** section to more info 

## Usage
`bash deployer.sh [a][i][r][b][d]`
- `a` - add target platform Android
- `i` - add target platform iOS
- `r` - set build mode to Release
- `b` - build project (game bundle will be in ./dist folder)
- `d` - deploy bundle to connected device
	- it will deploy && run bundle on Android
	- it will only deploy bundle on iOS (for now)

Bundle files will be located at *./dist/bundle*
If no version finded in `game.project`, it will be *0.0.0* as default
With name {ProjectName}\_{Version}\_{BuildMode}.[apk|ipa]

##	Example
`./deployer.sh abd` - build, deploy and run Android bundle
`./deployer.sh ird` - build and deploy iOS release bundle
`./deployer.sh aibr` - build Android and iOS release bundles

You can pass params in any order you want, for example:
`./deployer.sh riba` - same behaviour as aibr

## Custom parameters
You can override global params for every project in `./custom_deployer` bash file on root of your project:
If this file exist, it will run inside this script
```bash
# path to bob folder. It will find and save new bob files inside
bob_folder={path}/
# path to android signature key
android_key={path}/key.pk8
# path to android signature certificate
android_cer={path}/certificate.pem
# ID of your ios development identity
ios_identity_dev="AAXBBYY"
# ID of your iod distribution identity
ios_identity_dist="YYBBXXAA"
# path to ios development mobileprovision
ios_prov_dev={path}/ios_dev.mobileprovision
# path to ios distribution mobileprovision
ios_prov_dist={path}/ios_dist.mobileprovision
# You can point bob version for project in format "{version:sha}"
bob_sha="156:67b68f1e1ac26a3385fb511cdce520fe52387bb0"
# If true, it will check and download latest bob versionn and it will ignore bob_sha
use_latest_bob=false
```

## Author
Insality
