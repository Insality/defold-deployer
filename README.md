![](defold-deployer.png)

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/insality/defold-deployer?style=for-the-badge)](https://github.com/Insality/defold-deployer/releases)

# Defold Deployer
Universal build && deploy script for *Defold* projects (Android, iOS, HTML5, Linux, MacOS, Windows)
**Deployer** is configurable via settings_deployer file. It's allow use single deployer script for different projects

## Features
- Single deployment script on all Defold projects (Android, iOS, HTML5, Linux, MacOS, Windows)
- One command to build, deploy and read logs from the mobile
- Global and custom settings on project (provisions, bob version, etc)
- Useful build output
- Save your time on preparing debug && release builds
- Nice naming builds to save history of product versions
- Auto *bob.jar* downloading. Flag **use_latest_bob** for using always last version of *Defold*
- Select Bob channel (stable/beta/alpha) and Defold build server via settings file
- Use incremental value for last number in version (enable via _enable incremental version_)
- Headless build && run for your unit-tests on CI
- Add additional info to *game.project*: *project.commit_sha*  and *project.build time*
- Android Instant build in one command (`deployer abr --instant`)
- Redownload dependencies, if they are corrupted

## Install
For bob build tool you need to install java JDK: https://openjdk.java.net/projects/jdk/11/

For ios deploy by cable you need to install:
- *ios-deploy*: https://github.com/ios-control/ios-deploy

For android deploy and read logs you need to install:
- *adb*: https://developer.android.com/studio/releases/platform-tools

For running `bob.jar` you need to install:
- *java*: https://openjdk.java.net/projects/jdk/11/

For HTML5 builds you need to install:
- Deployer use `zip` command to pack HTML5 build into zip file
- Deployer use `python 2` to run HTTP Server for deploy

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
`bash deployer.sh [a][i][h][w][l][m][r][b][d] [--fast] [--resolve] [--instant] [--settings {filename}] [--headless]`
- `a` - add target platform Android
- `i` - add target platform iOS
- `h` - add target platform HTML5
- `w` - add target platform Windows
- `l`- add target platform Linux
- `m` - add target platform MacOS
- `r` - set build mode to Release
- `b` - build project (game bundle will be in ./dist/bundle/ folder)
- `d` - deploy bundle && run to connected device. Auto start logging from connected device
- `--settings {filename}` - add settings file to build params. Can be used several times
- `--fast` - build only one Android platform (for faster builds)
- `--headless` - set mode to headless. Override release mode
- `--resolve` - build with dependency resolve
- `--instant` - it preparing bundle for Android Instant Apps. Always in release mode

Bundle files will be located at *./dist/bundle/{Version}/*

If no version found in `game.project`, it will be *0.0.0* as default

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
# Build and run HTML5 debug build
deployer.sh hdb
# Build and preparing Android Instant Apps bundle
deployer.sh ab --instant
# Build, deploy and run Android bundle in fast mode (useful for testing)
deployer.sh abd --fast
# You can pass params in any order you want, for example:
# Same behaviour as aibr
deployer.sh riba
# Build MacOS debug build and run it
deployer.sh mbd
# Build linux headless build with unit_test.txt settings and run it
deployer.sh lbd --settings unit_test.txt --headless 
# Build Windows release build
deployer.sh wbr
```

## Deployer parameters
- **Global settings** setup by `settings_deployer` file nearby with deployer script
- **Custom project settings** setup by `settings_deployer` file nearby your `game.project` file on root of your project:

Copy `settings_deployer.template` with name `settings_deployer` and change it for your needs

Deployer parameters:
```bash
# Path to bob folder. It will find and save new bob.jar files inside
bob_folder={path_to_bob_folder}

# Path to android keystore for debug
android_keystore_dev={path_to_keystore.jks}

# Path to android keystore for release
android_keystore_dist={path_to_keystore.jks}

# Path to android keystore password for debug. This file should contains keystore password
android_keystore_password_dev="{path_to_keystore_password.txt}"

# Path to android keystore password for release. This file should contains keystore password
android_keystore_password_dist="{path_to_keystore_password.txt}"

# ID of your ios development identity
ios_identity_dev="AAXBBYY"

# ID of your iod distribution identity
ios_identity_dist="YYBBXXAA"

# Path to ios development mobileprovision
ios_prov_dev={path_to_ios_dev.mobileprovision}

# Path to ios distribution mobileprovision
ios_prov_dist={path_to_ios_dist.mobileprovision}

# You can point bob version for project in format "filename:sha"
bob_sha="173:fe2b689302e79b7cf8c0bc7d934f23587b268c8a"

# Select Defold channel. Values: stable, beta
bob_channel="stable"

# If true, it will check and download latest bob version. It will ignore bob_sha param
use_latest_bob=false

# Select Defold build server
build_server="https://build.defold.com"

# Set patch game version value as total git commits count (1.2.0 -> 1.2.{commits_count})
# You allow to get SHA commit from version via: git rev-list --all --reverse | sed -n {N}p
enable_incremental_version=false

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

# Path to android signature key for release (Since Defold 174 only using for Android Instant games)
android_key_dist={path_to_key.pk8}

# Path to android signature certificate for release (Since Defold 174 only using for Android Instant games)
android_cer_dist={path_to_certificate.pem}
```

## Author
Maxim Tuprikov, [Insality](http://github.com/Insality)
**MIT** License


## Issues and suggestions

If you have any issues, questions or suggestions please  [create an issue](https://github.com/Insality/druid/issues)  or contact me:  [insality@gmail.com](mailto:insality@gmail.com)

