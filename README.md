
![](defold-deployer.png)
# Defold Deployer
Unique build && deploy script for mobile projects (Android, iOS), Defold Engine

## Features
- Single deployment script on all Defold mobile projects (Android, iOS)
- One command to build, deploy and read logs from the mobile
- Global and custom settings on project (provisions, bob version, etc)
- Save your time on preparing debug && release builds
- Nice naming builds to save history of product versions
- Auto *bob.jar* downloading. Flag **use_latest_bob** for using always last version of Defold
- Android Instant build in one command (`deployer abr --instant`)
- Redownload dependencies, if they are corrupted

## Install
For bob build tool you need to install java JDK: https://openjdk.java.net/projects/jdk/11/

For ios deploy by cable you need to install:
- *ios-deloy*: https://github.com/ios-control/ios-deploy

For android deploy and read logs you need to install:
- *adb*: https://developer.android.com/studio/releases/platform-tools

For running `bob.jar` you need to install:
- *java*: https://openjdk.java.net/projects/jdk/11/

For building Android Instant you need to make prepare:
- *Insctructions*: [https://forum.defold.com/t/instruction-android-instant-app-creation/48471](https://forum.defold.com/t/instruction-android-instant-app-creation/48471)
 - Deployer use `zip` command to prepare bundle for _Google Play_


## Setup
Run `deployer.sh` inside your `game.project` folder.

To create your settings file, just copy `setting_deployer.template` with name `settings_deployer` and place it in right place:

- **Global settings** - `settings_deployer` file nearby `deployer.sh` script
- **Custom project settings** - `settings_deployer` file nearby `game.project` file

Custom projects settings will override your global settings

#### Recommendation
Make link to `deployer.sh` file in your system path with name `deployer` (via `ln -s deployer.sh deployer`)

Add execution mode to it via `chmod +x` 

Place your **global settings** file nearby new `deployer` file link

Call it in your project folder like: `deployer abd`


## Usage
`bash deployer.sh [a][i][r][b][d] [--instant] [--fast] [--noresolve]`
- `a` - add target platform Android
- `i` - add target platform iOS
- `r` - set build mode to Release
- `b` - build project (game bundle will be in ./dist/bundle/ folder)
- `d` - deploy bundle && run to connected device. Auto start logging from connected device
- `--instant` - make builder mode to Android Instant. It will always build in _Release_ mode
- `--fast` - build without resolve and only one Android platform (for faster builds)
- `--noresolve` - build without dependency resolve

Bundle files will be located at *./dist/bundle/{Version}/*

If no version finded in `game.project`, it will be *0.0.0* as default

Deployer need to run on root of your Defold project

Filename will be name {ProjectName}\_{Version}\_{BuildMode}.[apk|ipa]

##	Examples
```bash
# Build, deploy and run Android bundle
deployer.sh abd
# Deploy and run iOS release bundle
deployer.sh ird
# Build Android and iOS release bundles
deployer.sh aibr
# Build and preparing Android Instant Apps bundle
deployer.sh ab --instant
# Build, deploy and run Android bundle in fast mode (useful for testing)
deployer.sh abd --fast
# You can pass params in any order you want, for example:
# Same behaviour as aibr
deployer.sh riba
```

## Deployer parameters
- **Global settings** setup by `settings_deployer` file nearby with deployer script
- **Custom project settings** setup by `settings_deployer` file nearby your `game.project` file on root of your project:

Copy `settings_deployer.template` with name `settings_deployer` and change it for your needs

Deployer parameters:
```bash
# Path to bob folder. It will find and save new bob.jar files inside
bob_folder={path_to_bob_folder}

# Path to android signature key for debug
android_key_dev={path_to_key.pk8}

# Path to android signature certificate for debug
android_cer_dev={path_to_certificate.pem}

# Path to android signature key for release
android_key_dist={path_to_key.pk8}

# Path to android signature certificate for release
android_cer_dist={path_to_certificate.pem}

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

# If true, it will check and download latest bob version. It will ignore bob_sha param
use_latest_bob=false

# If true, add `-l yes` build param for publish live content
is_live_content=false

# Set to true, if you do not need to strip executables
no_strip_executable=false

# Android instant app settings.ini path to override
# (Usually, you need it to override AndroidManifest.xml)
# See instruction here: https://forum.defold.com/t/instruction-android-instant-app-creation/48471
android_instant_app_settings={path_to_android_settings_ini}

# SDK path to build Android Instant app
sdk_path={path_to_android_sdk}
```

## Author
Maxim Tuprikov, [Insality](http://github.com/Insality)
MIT License

