#!/bin/bash
### Author: Insality <insality@gmail.com>, 04.2019
## (c) Insality Games
##
## Unique build && deploy script for mobile projects (Android, iOS)
## for Defold Engine.
##
## Install:
## See full instructions here: https://github.com/Insality/defold-deployer/blob/master/README.md
##
## Usage:
## bash deployer.sh [a][i][r][b][d] [--instant]
## 	a - add target platform Android
## 	i - add target platform iOS
## 	r - set build mode to Release
## 	b - build project (game bundle will be in ./dist folder)
## 	d - deploy bundle to connected device
## 		it will deploy && run bundle on Android/iOS with reading logs to terminal
## 	--instant - it preparing bundle for Android Instant Apps (always in release mode)
##
## 	Example:
##		./deployer.sh abd - build, deploy and run Android bundle
## 	./deployer.sh ibd - build, deploy and run iOS release bundle
## 	./deployer.sh aibr - build Android and iOS release bundles
##
## 	You can pass params in any order you want, for example:
## 	./deployer.sh riba - same behaviour as aibr
##

# Exit on Cmd+C / Ctrl+C
trap "exit" INT

if [ ! -f ./game.project ]; then
	echo -e "\x1B[31m[ERROR]: ./game.project not exist\x1B[0m"
	exit
fi


# Game project settings for deployer script
title=$(less game.project | grep "^title = " | cut -d "=" -f2 | sed -e 's/^[[:space:]]*//')
version=$(less game.project | grep "^version = " | cut -d "=" -f2 | sed -e 's/^[[:space:]]*//')
version=${version:='0.0.0'}
title_no_space=$(echo -e "${title}" | tr -d '[[:space:]]')
bundle_id=$(less game.project | grep "^package = " | cut -d "=" -f2 | sed -e 's/^[[:space:]]*//')
file_prefix_name="${title_no_space}_${version}"
android_platform="armv7-android"
ios_platform="armv7-darwin"

settings_filename="settings_deployer"
dist_folder="./dist"
bundle_folder="${dist_folder}/bundle"
version_folder="${bundle_folder}/${version}"


echo -e "\nProject: \x1B[36m${title} v${version}\x1B[0m"


### SETTINGS LOADING
script_path="`dirname \"$0\"`"
is_settings_exist=false

if [ -f ${script_path}/${settings_filename} ]; then
	is_settings_exist=true
	echo "Using default deployer settings from ${script_path}/${settings_filename}"
	source ${script_path}/${settings_filename}
fi

if [ -f ./${settings_filename} ]; then
	is_settings_exist=true
	echo "Using custom deployer settings for ${title} from ${PWD}/${settings_filename}"
	source ./${settings_filename}
fi

if ! $is_settings_exist ; then
	echo -e "\x1B[31m[ERROR]: No deployer settings file founded\x1B[0m"
	echo "Place your default deployer settings at ${script_path}/"
	echo "Place your project settings at root of your game project (./)"
	echo "File name should be '${settings_filename}'"
	echo "See template of settings here: https://github.com/Insality/defold-deployer"
	exit
fi


### BOB SELECT
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

echo -e "Using bob version \x1B[35m${bob_version}\x1B[0m SHA: ${bob_sha}"

bob_path="${bob_folder}bob${bob_version}.jar"
if [ ! -f ${bob_path} ]; then
	# Get the bob from SHA1
	# SHA1=$(curl -s http://d.defold.com/stable/info.json | sed 's/.*sha1": "\(.*\)".*/\1/')
	BOB_URL="http://d.defold.com/archive/${bob_sha}/bob/bob.jar"
	echo "Unable to find bob${bob_version}.jar. Downloading it from d.defold.com: ${BOB_URL}}"
	curl -o ${bob_path} ${BOB_URL}
fi


try_fix_libraries() {
	echo "Possibly, libs was corrupted (interupt script while resolving libraries)"
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

	args="-jar ${bob_path} --archive -bo ${dist_folder} --variant $@"

	if ! $no_strip_executable; then
		args+=" --strip-executable"
	fi

	if [ ${mode} == "debug" ]; then
		echo "Build without distclean and compression for faster build time"
		args+=" build bundle"
	fi

	if [ ${mode} == "release" ]; then
		echo "Build with distclean and compression. Release mode"
		args+=" -tc true build bundle distclean"
	fi

	echo -e "\nBuild command: java ${args}"
	java ${args}
}


build() {
	if [ ! -d ${dist_folder} ]; then
		mkdir ${dist_folder}
	fi
	if [ ! -d ${bundle_folder} ]; then
		mkdir ${bundle_folder}
	fi
	if [ ! -d ${version_folder} ]; then
		mkdir ${version_folder}
	fi
	platform=$1
	mode=$2
	additional_params=$3

	if [ ${mode} == "release" ]; then
		ident=${ios_identity_dist}
		prov=${ios_prov_dist}
		android_cer=${android_cer_dist}
		android_key=${android_key_dist}
		echo -e "\x1B[32mBuild in Release mode\x1B[0m"
	else
		ident=${ios_identity_dev}
		prov=${ios_prov_dev}
		android_cer=${android_cer_dev}
		android_key=${android_key_dev}
		echo -e "\x1B[31mBuild in Debug mode\x1B[0m"
	fi

	resolve_bob

	filename="${file_prefix_name}_${mode}"

	# Android platform
	if [ ${platform} == ${android_platform} ]; then
		line="${dist_folder}/${title}/${title}"

		echo "Start build android ${mode}"
		bob ${mode} -brhtml ${version_folder}/${filename}_report.html \
			--platform ${platform} -pk ${android_key} -ce ${android_cer} ${additional_params}

		mv "${line}.apk" "${version_folder}/${filename}.apk"
		echo -e "\x1B[32mSave APK bundle at ${version_folder}/${filename}.apk\x1B[0m"
	fi

	# iOS platform
	if [ ${platform} == ${ios_platform} ]; then
		line="${dist_folder}/${title}"

		echo "Start build ios ${mode}"
		bob ${mode} -brhtml ${version_folder}/${filename}_report.html \
			--platform ${platform} --identity ${ident} -mp ${prov} ${additional_params}

		mv "${line}.app" "${version_folder}/${filename}.app"
		mv "${line}.ipa" "${version_folder}/${filename}.ipa"
		echo -e "\x1B[32mSave IPA bundle at ${version_folder}/${filename}.ipa\x1B[0m"
	fi
}


make_instant() {
	mode=$1
	echo -e "\nPreparing APK for Android Instant game"
	filename="${version_folder}/${file_prefix_name}_${mode}.apk"
	filename_instant="${version_folder}/${file_prefix_name}_${mode}_align.apk"
	filename_instant_zip="${version_folder}/${file_prefix_name}_${mode}.apk.zip"
	${sdk_path}/zipalign -f 4 ${filename} ${filename_instant}
	${sdk_path}/apksigner sign --key ${android_key_dist} --cert ${android_cer_dist} ${filename_instant}
	zip -j ${filename_instant_zip} ${filename_instant}
	rm ${filename}
	rm ${filename_instant}
	echo -e "\x1B[32mZip file for Android instant ready: ${filename_instant_zip}\x1B[0m"
}


deploy() {
	platform=$1
	mode=$2
	if [ ${platform} == ${android_platform} ]; then
		filename="${version_folder}/${file_prefix_name}_${mode}.apk"
		echo "Deploy to Android from ${filename}"
		adb install -r "${filename}"
	fi

	if [ ${platform} == ${ios_platform} ]; then
		filename="${version_folder}/${file_prefix_name}_${mode}.ipa"
		echo "Deploy to iOS from ${filename}"
		ios-deploy --bundle "${filename}"
	fi
}


run() {
	platform=$1
	echo "Start game ${bundle_id}"

	if [ ${platform} == ${android_platform} ]; then
		adb shell am start -n ${bundle_id}/com.dynamo.android.DefoldActivity
		adb logcat -s defold
	fi

	if [ ${platform} == ${ios_platform} ]; then
		filename_app="${version_folder}/${file_prefix_name}_${mode}.app"
		ios-deploy -I -m -b ${filename_app} | grep ${title_no_space}
	fi
}


### ARGS PARSING
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
			file_prefix_name+="_instant"
			shift
		;;
		*) # Unknown option
			shift
		;;
	esac
done


### DEPLOYER RUN
if $is_ios
then
	if $is_build; then
		echo -e "\nStart build on \x1B[36m${ios_platform}\x1B[0m"
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
		if $is_build; then
			echo -e "\nStart build on \x1B[34m${android_platform}\x1B[0m"
			build ${android_platform} ${mode}
		fi

		if $is_deploy; then
			echo "Start deploy project to device"
			deploy ${android_platform} ${mode}
			run ${android_platform}
		fi
	else
		# Build Android Instant APK
		echo -e "\nStart build on \x1B[34m${android_platform} Instant APK\x1B[0m"
		build ${android_platform} ${mode} "--settings ${android_instant_app_settings}"
		make_instant ${mode}

		if $is_deploy; then
			echo "No autodeploy for Instant APK builds..."
		fi
	fi
fi

echo "End of deployer build"
