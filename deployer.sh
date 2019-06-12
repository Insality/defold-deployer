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
## bash deployer.sh [a][i][r][b][d]
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
## Deployer params can be overrided with ./custom_deployer script
## If this file exist, it will run inside this script
##
## Just declare new global vars inside custom_deployer like this:
##
## 	ios_prov_dev=./provisions/dev.mobileprovision
## 	ios_identity_dev="AAABBCUSTOM"
## 	bob_sha="155:838cecd7a26c932e6be73421d98e51ba12f1d462"
##

## Setup provisions and certificates for your project
## Global settings. Override it in ./custom_deployer
bob_folder={path}/
android_key={path}/key.pk8
android_cer={path}/certificate.pem
ios_identity_dev="AAXBBYY"
ios_identity_dist="YYBBXXAA"
ios_prov_dev={path}/ios_dev.mobileprovision
ios_prov_dist={path}/ios_dist.mobileprovision
bob_sha="156:67b68f1e1ac26a3385fb511cdce520fe52387bb0" # You can point bob version for project
use_latest_bob=false # If true, it will check and download latest bob version. Ignore bob_sha

# Exit on Cmd+C / Ctrl+C
trap "exit" INT

title=$(less game.project | grep "^title = " | cut -d "=" -f2 | sed -e 's/^[[:space:]]*//')
version=$(less game.project | grep "^version = " | cut -d "=" -f2 | sed -e 's/^[[:space:]]*//')
version=${version:='0.0.0'}
title_no_space=$(echo -e "${title}" | tr -d '[[:space:]]')
bundle_id=$(less game.project | grep "^package = " | cut -d "=" -f2 | sed -e 's/^[[:space:]]*//')
file_prefix_name="${title_no_space}_${version}"
android_platform="armv7-android"
ios_platform="armv7-darwin"

if [ -f ./custom_deployer ]; then
	echo "Use custom deployer settings for ${title}"
	source custom_deployer
fi

bob_version="$(cut -d ":" -f1 <<< "$bob_sha")"
bob_sha="$(cut -d ":" -f2 <<< "$bob_sha")"

echo "Project: ${title} v${version}"
echo "Using bob version ${bob_version}"

if $use_latest_bob; then
	INFO=$(curl -s http://d.defold.com/stable/info.json)
	echo "Latest bob: ${INFO}"
	bob_sha=$(sed 's/.*sha1": "\(.*\)".*/\1/' <<< $INFO)
	bob_version=$(sed 's/[^0-9.]*\([0-9.]*\).*/\1/' <<< $INFO)
	bob_version="$(cut -d "." -f3 <<< "$bob_version")"
fi

bob_path="${bob_folder}bob${bob_version}.jar"
if [ ! -f ${bob_path} ]; then
	# Get the bob from SHA1
	# SHA1=$(curl -s http://d.defold.com/stable/info.json | sed 's/.*sha1": "\(.*\)".*/\1/')
	BOB_URL="http://d.defold.com/archive/${bob_sha}/bob/bob.jar"
	echo "Unable to find bob${bob_version}.jar. Downloading it from d.defold.com: ${BOB_URL}}"
	curl -o ${bob_path} ${BOB_URL}
fi

resolve_bob() {
	java -jar ${bob_path} --email foo@bar.com --auth 12345 resolve
}

bob() {
	mode=$1
	java -jar ${bob_path} --version

	if [ ${mode} == "debug" ]; then
		echo "Build without distclean and compression for faster build time"
		java -jar ${bob_path} --archive -bo ./dist \
			--strip-executable $@ build bundle
	fi

	if [ ${mode} == "release" ]; then
		echo "Build with distclean and compression. Release mode"
		java -jar ${bob_path} --archive -tc true -bo ./dist \
			--strip-executable $@ distclean build bundle
	fi
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
			--platform ${platform} -pk ${android_key} -ce ${android_cer} \
			--variant ${mode}

		line="./dist/${title}/${title}.apk"
		filename="${file_prefix_name}_${mode}.apk"
		mv "${line}" "./dist/bundle/${filename}"
		echo "Save APK bundle at ./dist/bundle/${filename}"
	fi

	# iOS platform
	if [ ${platform} == ${ios_platform} ]; then
		echo "Start build ios ${mode}"
		bob ${mode} -brhtml ./dist/${platform}_report.html \
			--platform ${platform} --identity ${ident} -mp ${prov}

		line="./dist/${title}.ipa"
		filename="${file_prefix_name}_${mode}.ipa"
		mv "${line}" "./dist/bundle/${filename}"
		echo "Save IPA bundle at ./dist/bundle/${filename}"
	fi
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
		echo "Deploy to Ios from ${filename}"
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
	if $is_build; then
		echo ""
		echo -e "Start build on \x1B[34m${android_platform}\x1B[0m"
		build ${android_platform} ${mode}
	fi

	if $is_deploy; then
		echo "Start deploy project to device"
		deploy ${android_platform} ${mode}
		run ${android_platform}
	fi
fi

echo "End of builder"