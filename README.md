
# Defold Deployer
Unique build && deploy script for mobile projects (Android, iOS) for Defold Engine

## Features
- Single deployment script on all Defold mobile projects
- One command to build, deploy and read logs from the mobile (now android only)
- Custom settings on project (provisions, bob version, etc)
- Save your time on preparing debug & release builds
- Nice naming builds to save history of product versions
- Auto *bob.jar* downloading. Flag **use_latest_bob** for using always last version of Defold
- Android Instant build in one command
- Repair dependencies, if they are corrupted

## Install
For bob build tool you need to install java 1.8

For ios deploy by cable you need to install:
*ios-deloy*: https://github.com/ios-control/ios-deploy

For android deploy and read logs you need to install:
*adb*: https://developer.android.com/studio/releases/platform-tools

For running `bob.jar` you need to install:
*java*: https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html

For building Android Instant you need to make prepare:
[https://forum.defold.com/t/instruction-android-instant-app-creation/48471](https://forum.defold.com/t/instruction-android-instant-app-creation/48471)
Deployer use `zip` command to prepare bundle for _Google Play_


## Setup
I recommend make link to `deployer.sh` in your path with name `deployer` (`ln -s deployer.sh deployer`), chmod +x it and call it in your project folder like:
`deployer abd`

Override global settings for your projects inside `deployer` scripts. See **custom parameters** section to more info 

To override global deployer settings, place `deployer_settings` file nearby deployer script file

## Usage
`bash deployer.sh [a][i][r][b][d] [--instant]`
- `a` - add target platform Android
- `i` - add target platform iOS
- `r` - set build mode to Release
- `b` - build project (game bundle will be in ./dist folder)
- `d` - deploy bundle to connected device
	- it will deploy && run bundle on Android
	- it will only deploy bundle on iOS (for now)
- `--instant` - make builder mode to Android Instant. It will always build in _Release_ mode

Bundle files will be located at *./dist/bundle*

If no version finded in `game.project`, it will be *0.0.0* as default

Deployer need to run on root of your Defold project

With name {ProjectName}\_{Version}\_{BuildMode}.[apk|ipa]

##	Example
`./deployer.sh abd` - build, deploy and run Android bundle

`./deployer.sh ird` - build and deploy iOS release bundle

`./deployer.sh aibr` - build Android and iOS release bundles

`./deployer.sh ab --instant` - build and preparing Android Instant Apps bundle

You can pass params in any order you want, for example:
`./deployer.sh riba` - same behaviour as aibr

## Deployer parameters
You can place global settings with file `deployer_settings` nearby with deployer script
You can override global params for your project in `./deployer_settings` bash file on root of your project:
Copy `deployer_settings.template` with name `deployer_settings` and change it for your needs
```bash
# Path to bob folder. It will find and save new bob files inside
bob_folder={path_to_bob_folder}

# Path to android signature key
android_key={path_to_key.pk8}

# Path to android signature certificate
android_cer={path_to_certificate.pem}

# ID of your ios development identity
ios_identity_dev="AAXBBYY"

# ID of your iod distribution identity
ios_identity_dist="YYBBXXAA"

# Path to ios development mobileprovision
ios_prov_dev={path_to_ios_dev.mobileprovision}

# Path to ios distribution mobileprovision
ios_prov_dist={path_to_ios_dist.mobileprovision}

# You can point bob version for project in format "version:sha"
bob_sha="161:45635ad26f85009c52905724e242cc92dd252146"

# If true, it will check and download latest bob versionn and it will ignore bob_sha
use_latest_bob=false

# Set to true, if you do not need to strip executables
no_strip_executable=false

# Android instant app settings.ini path to override
# (Usually, you need it to override AndroidManifest.xml)
android_instant_app_settings={path_to_android_settings_ini}

# SDK path to build Android Instant app
sdk_path={path_to_android_sdk}
```

## Author
Insality
