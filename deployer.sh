#!/bin/bash
### Author: Insality <insality@gmail.com>, 04.2019
## (c) Insality Games
##
## Unique build && deploy script for mobile projects (Android, iOS)
## for Defold Engine.
##
## Install:
## ios-deloy: https://github.com/ios-control/ios-deploy
## adb: https://developer.android.com/studio/releases/platform-tools
## java: https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
##
##	Bundle files will be located at ./dist/bundle
## With name {ProjectName}_{Version}_{BuildMode}.[apk|ipa]
##
## Usage:
## bash deployer.sh [a][i][r][b][d] [--instant]
## 	a - add target platform Android
## 	i - add target platform iOS
## 	r - set build mode to Release
## 	b - build project (game bundle will be in ./dist folder)
## 	d - deploy bundle to connected device
## 		it will deploy && run bundle on Android
## 		it will only deploy bundle on iOS (for now)
##
## 	Example:
##		./deployer.sh abd - build, deploy and run Android bundle
## 	./deployer.sh ird - build and deploy iOS release bundle
## 	./deployer.sh aibr - build Android and iOS release bundles
##
## 	You can pass params in any order you want, for example:
## 	./deployer.sh riba - same behaviour as aibr
##
## Custom parameters:
## You can setup custom parameters (like provisions, keys and certificate, bob version)
## Deployer params can be overrided with ./deployer_settings script
## If this file exist, it will run inside this script
##
## Just declare new global vars inside deployer_settings like this:
##
## 	ios_prov_dev=./provisions/dev.mobileprovision
## 	ios_identity_dev="AAABBCUSTOM"
## 	bob_sha="155:838cecd7a26c932e6be73421d98e51ba12f1d462"
##

## Setup provisions and certificates for your project
## Global settings. Override it in ./deployer_settings


# Exit on Cmd+C / Ctrl+C
trap "exit" INT

script_path="`dirname \"$0\"`"
is_settings_exist=false

if [ ! -f ./game.project ]; then
	echo -e "\x1B[31m[ERROR]: ./game.project not exist\x1B[0m"
	exit
fi


# Game project settings for deployer
title=$(less game.project | grep "^title = " | cut -d "=" -f2 | sed -e 's/^[[:space:]]*//')
version=$(less game.project | grep "^version = " | cut -d "=" -f2 | sed -e 's/^[[:space:]]*//')
version=${version:='0.0.0'}
title_no_space=$(echo -e "${title}" | tr -d '[[:space:]]')
bundle_id=$(less game.project | grep "^package = " | cut -d "=" -f2 | sed -e 's/^[[:space:]]*//')
file_prefix_name="${title_no_space}_${version}"
android_platform="armv7-android"
ios_platform="armv7-darwin"

echo ""
echo "Project: ${title} v${version}"


if [ -f ${script_path}/deployer_settings ]; then
	is_settings_exist=true
	echo "Using default deployer settings from ${script_path}/deployer_settings"
	source ${script_path}/deployer_settings
fi

if [ -f ./deployer_settings ]; then
	is_settings_exist=true
	echo "Using custom deployer settings for ${title} from ${PWD}/deployer_settings"
	source ./deployer_settings
fi

if ! $is_settings_exist ; then
	echo -e "\x1B[31m[ERROR]: No deployer settings file founded\x1B[0m"
	echo "Place your default deployer settings at ${script_path}/"
	echo "Place your project settings at root of your game project (./)"
	echo "File name should be 'deployer_settings'"
	echo "See template of settings here: https://github.com/Insality/defold-deployer"
	exit
fi

bob_version="$(cut -d ":" -f1 <<< "$bob_sha")"
bob_sha="$(cut -d ":" -f2 <<< "$bob_sha")"

if $use_latest_bob; then
	INFO=$(curl -s http://d.defold.com/stable/info.json)
	echo "Latest bob: ${INFO}"
	bob_sha=$(sed 's/.*sha1": "\(.*\)".*/\1/' <<< $INFO)
	echo ${bob_sha}
	bob_version=$(sed 's/[^0-9.]*\([0-9.]*\).*/\1/' <<< $INFO)
	bob_version="$(cut -d "." -f3 <<< "$bob_version")"
	echo ${bob_versio}
fi

echo "Using bob version ${bob_version} SHA: ${bob_sha}"

bob_path="${bob_folder}bob${bob_version}.jar"
if [ ! -f ${bob_path} ]; then
	# Get the bob from SHA1
	# SHA1=$(curl -s http://d.defold.com/stable/info.json | sed 's/.*sha1": "\(.*\)".*/\1/')
	BOB_URL="http://d.defold.com/archive/${bob_sha}/bob/bob.jar"
	echo "Unable to find bob${bob_version}.jar. Downloading it from d.defold.com: ${BOB_URL}}"
	curl -o ${bob_path} ${BOB_URL}
fi

try_fix_libraries() {
	echo "Possibly, libs was corrupter (interupt script while resolving libraries)"
	echo "Trying to delete and redownload it (./.internal/lib/)"
	rm -r ./.internal/lib/
	java -jar ${bob_path} --email foo@bar.com --auth 12345 resolve
}

resolve_bob() {
	echo "Resolving libraries..."
	java -jar ${bob_path} --email foo@bar.com --auth 12345 resolve || try_fix_libraries
}

bob() {
	echo "Building project..."
	mode=$1
	java -jar ${bob_path} --version

	args="-jar ${bob_path} --archive -bo ./dist --strip-executable --variant $@"

	if [ ${mode} == "debug" ]; then
		echo "Build without distclean and compression for faster build time"
		echo ""
		args+=" build bundle"
	fi

	if [ ${mode} == "release" ]; then
		echo "Build with distclean and compression. Release mode"
		echo ""
		args+=" -tc true build bundle distclean"
	fi

	echo "Build command: java ${args}"
	java ${args}
}

build() {
	if [ ! -d ./dist ]; then
		mkdir ./dist
	fi
	if [ ! -d ./dist/bundle ]; then
		mkdir ./dist/bundle
	fi
	platform=$1
	mode=$2
	additional_params=$3
	ident=${ios_identity_dev}
	prov=${ios_prov_dev}
	if [ ${mode} == "release" ]; then
		ident=${ios_identity_dist}
		prov=${ios_prov_dist}
		echo -e "\x1B[32mBuild in Release mode\x1B[0m"
	else
		echo -e "\x1B[31mBuild in Debug mode\x1B[0m"
	fi

	resolve_bob

	# Android platform
	if [ ${platform} == ${android_platform} ]; then
		# Later add --architectures armv7-android,arm64-android
		# for both architectures 32 and 64
		echo "Start build android ${mode}"
		bob ${mode} -brhtml ./dist/${platform}_report.html \
			--platform ${platform} -pk ${android_key} -ce ${android_cer} ${additional_params}

		line="./dist/${title}/${title}.apk"
		filename="${file_prefix_name}_${mode}.apk"
		mv "${line}" "./dist/bundle/${filename}"
		echo -e "\x1B[32mSave APK bundle at ./dist/bundle/${filename}\x1B[0m"
	fi

	# iOS platform
	if [ ${platform} == ${ios_platform} ]; then
		echo "Start build ios ${mode}"
		bob ${mode} -brhtml ./dist/${platform}_report.html \
			--platform ${platform} --identity ${ident} -mp ${prov} ${additional_params}

		line="./dist/${title}.ipa"
		filename="${file_prefix_name}_${mode}.ipa"
		mv "${line}" "./dist/bundle/${filename}"
		echo -e "\x1B[32mSave IPA bundle at ./dist/bundle/${filename}\x1B[0m"
	fi
}

make_instant() {
	mode=$1
	echo ""
	echo "Preparing APK for Android Instant game"
	filename="./dist/bundle/${file_prefix_name}_${mode}.apk"
	filename_insant="./dist/bundle/${file_prefix_name}_${mode}_insant.apk"
	filename_insant_zip="./dist/bundle/${file_prefix_name}_${mode}_insant.apk.zip"
	${sdk_path}/zipalign -f 4 ${filename} ${filename_insant}
	${sdk_path}/apksigner sign --key ${android_key} --cert ${android_cer} ${filename_insant}
	zip ${filename_insant_zip} ${filename_insant}
	echo -e "\x1B[32mZip file for Android instant ready: ${filename_insant_zip}\x1B[0m"
}

deploy() {
	platform=$1
	mode=$2
	if [ ${platform} == ${android_platform} ]; then
		filename="./dist/bundle/${file_prefix_name}_${mode}.apk"
		echo "Deploy to Android from ${filename}"
		adb install -r "${filename}"
	fi

	if [ ${platform} == ${ios_platform} ]; then
		filename="./dist/bundle/${file_prefix_name}_${mode}.ipa"
		echo "Deploy to iOS from ${filename}"
		ios-deploy --bundle "${filename}"
	fi
}

run() {
	platform=$1
	if [ ${platform} == ${android_platform} ]; then
		echo "Start game ${bundle_id}"
		adb shell am start -n ${bundle_id}/com.dynamo.android.DefoldActivity
		adb logcat -s defold
	fi
	if [ ${platform} == ${ios_platform}  ]; then
		echo "Can't run ipa on iOS"
	fi
}

arg=$1
is_build=false
is_deploy=false
is_android=false
is_ios=false
is_android_instant=false
mode="debug"

for (( i=0; i<${#arg}; i++ )); do
	a=${arg:$i:1}
	if [ $a == b ]; then
		is_build=true
	fi
	if [ $a == "d" ]; then
		is_deploy=true
	fi
	if [ $a == "r" ]; then
		mode="release"
	fi
	if [ $a == "a" ]; then
		is_android=true
	fi
	if [ $a == "i" ]; then
		is_ios=true
	fi
done

shift
while [[ $# -gt 0 ]]
do
	key=$1

	case $key in
		--instant)
			is_android_instant=true
			mode="release"
			shift
		;;
		*) # Unknown option
			shift
		;;
	esac
done


if $is_ios
then
	if $is_build; then
		echo ""
		echo -e "Start build on \x1B[36m${ios_platform}\x1B[0m"
		build ${ios_platform} ${mode}
	fi

	if $is_deploy; then
		echo "Start deploy project to device"
		deploy ${ios_platform} ${mode}
		run ${ios_platform}
	fi
fi

if $is_android
then
	if ! $is_android_instant; then
		# Just build usual Android build
		if $is_build ; then
			echo ""
			echo -e "Start build on \x1B[34m${android_platform}\x1B[0m"
			build ${android_platform} ${mode}
		fi

		if $is_deploy; then
			echo "Start deploy project to device"
			deploy ${android_platform} ${mode}
			run ${android_platform}
		fi
	else
		# Build Android Instant APK
		echo ""
		echo -e "Start build on \x1B[34m${android_platform} Instant APK\x1B[0m"
		build ${android_platform} ${mode} "--settings=${android_instant_app_settings}"
		make_instant ${mode}

		if $is_deploy; then
			echo "No autodeploy for Insant APK builds..."
		fi
	fi
fi

echo "End of deployer build"