#!/bin/bash
### Author: Insality <insality@gmail.com>, 04.2019
## (c) Insality Games
##
## Unique build && deploy script for mobile projects (Android, iOS, HTML5)
## for Defold Engine.
##
## Install:
## See full instructions here: https://github.com/Insality/defold-deployer/blob/master/README.md
##
## Usage:
## bash deployer.sh [a][i][h][r][b][d] [--instant] [--fast] [--no-resolve]
## 	a - add target platform Android
## 	i - add target platform iOS
## 	h - add target platform HTML5
## 	w - add target platform Windows
## 	l - add target platform Linux
## 	m - add target platform MacOS
## 	r - set build mode to Release
## 	b - build project (game bundle will be in ./dist folder)
## 	d - deploy bundle to connected device
## 		it will deploy && run bundle on Android/iOS with reading logs to terminal
## 	--instant - it preparing bundle for Android Instant Apps (always in release mode)
## 	--fast - build without resolve and only one Android platform (for faster builds)
## 	--no-resolve - build without dependency resolve
## 	--headless - set mode to headless. Override release mode
## 	--settings - add settings file to build params. Can be used several times
## 	--param {x} - add flag {x} to bob.jar. Can be used several times
##
## 	Example:
##		./deployer.sh abd - build, deploy and run Android bundle
## 	./deployer.sh ibdr - build, deploy and run iOS release bundle
## 	./deployer.sh aibr - build Android and iOS release bundles
##
## 	You can pass params in any order you want, for example:
## 	./deployer.sh riba - same behaviour as aibr
##

### Exit on Cmd+C / Ctrl+C
trap "exit" INT
trap clean EXIT
set -e

if [ ! -f ./game.project ]; then
	echo -e "\x1B[31m[ERROR]: ./game.project not exist\x1B[0m"
	exit
fi


### SETTINGS LOADING
settings_filename="settings_deployer"
script_path="`dirname \"$0\"`"
is_settings_exist=false

if [ -f ${script_path}/${settings_filename} ]; then
	is_settings_exist=true
	echo -e "Using default deployer settings from \x1B[33m${script_path}/${settings_filename}\x1B[0m"
	source ${script_path}/${settings_filename}
fi

if [ -f ./${settings_filename} ]; then
	is_settings_exist=true
	echo -e "Using custom deployer settings from \x1B[33m${PWD}/${settings_filename}\x1B[0m"
	source ./${settings_filename}
fi

if ! $is_settings_exist ; then
	echo -e "\x1B[31m[ERROR]: No deployer settings file founded\x1B[0m"
	echo "Place your default deployer settings at ${script_path}/"
	echo "Place your project settings at root of your game project (./)"
	echo "File name should be '${settings_filename}'"
	echo "See settings template here: https://github.com/Insality/defold-deployer"
	exit
fi


### Constants
commit_sha=`git rev-parse --verify HEAD`
build_time=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
android_platform="armv7-android"
ios_platform="armv7-darwin"
html_platform="js-web"
linux_platform="x86_64-linux"
windows_platform="x86_64-win32"
macos_platform="x86_64-darwin"
version_settings_filename="deployer_version_settings.txt"
dist_folder="./dist"
bundle_folder="${dist_folder}/bundle"


### Game project settings for deployer script
title=$(less game.project | grep "^title = " | cut -d "=" -f2 | sed -e 's/^[[:space:]]*//')
version=$(less game.project | grep "^version = " | cut -d "=" -f2 | sed -e 's/^[[:space:]]*//')
version=${version:='0.0.0'}
title_no_space=$(echo -e "${title}" | tr -d '[[:space:]]')
bundle_id=$(less game.project | grep "^package = " | cut -d "=" -f2 | sed -e 's/^[[:space:]]*//')

### Override last version number with commits count
if $set_commits_to_version; then
	commits_count=`git rev-list --all --count`
	version="${version%.*}.$commits_count"
fi

file_prefix_name="${title_no_space}_${version}"
version_folder="${bundle_folder}/${version}"
echo -e "\nProject: \x1B[36m${title} v${version}\x1B[0m SHA: \x1B[35m${commit_sha}\x1B[0m"


### Bob select
bob_version="$(cut -d ":" -f1 <<< "$bob_sha")"
bob_sha="$(cut -d ":" -f2 <<< "$bob_sha")"
bob_channel="${bob_channel:-"stable"}"

if $use_latest_bob; then
	INFO=$(curl -s http://d.defold.com/${bob_channel}/info.json)
	echo "Latest bob: ${INFO}"
	bob_sha=$(sed 's/.*sha1": "\(.*\)".*/\1/' <<< $INFO)
	echo ${bob_sha}
	bob_version=$(sed 's/[^0-9.]*\([0-9.]*\).*/\1/' <<< $INFO)
	bob_version="$(cut -d "." -f3 <<< "$bob_version")"
	echo ${bob_version}
fi

echo -e "Using Bob version \x1B[35m${bob_version}\x1B[0m SHA: \x1B[35m${bob_sha}\x1B[0m"

bob_path="${bob_folder}bob${bob_version}.jar"
if [ ! -f ${bob_path} ]; then
	BOB_URL="https://d.defold.com/archive/${bob_channel}/${bob_sha}/bob/bob.jar"
	echo "Unable to find bob${bob_version}.jar. Downloading it from d.defold.com: ${BOB_URL}}"
	echo "curl -L -o ${bob_path} ${BOB_URL}"
	curl -L -o ${bob_path} ${BOB_URL}
fi


try_fix_libraries() {
	echo "Possibly, libs was corrupted (script interrupted while resolving libraries)"
	echo "Trying to delete and redownload it (./.internal/lib/)"
	rm -r ./.internal/lib/
	java -jar ${bob_path} --email foo@bar.com --auth 12345 resolve
}


resolve_bob() {
	echo "Resolving libraries..."
	java -jar ${bob_path} --email foo@bar.com --auth 12345 resolve || try_fix_libraries
	echo ""
}


bob() {
	mode=$1
	java --version
	java -jar ${bob_path} --version

	args="-jar ${bob_path} --archive -bo ${dist_folder} --variant $@"

	if ! $no_strip_executable; then
		args+=" --strip-executable"
	fi

	if [ ${mode} == "debug" ]; then
		echo "Build without distclean and compression. Debug mode"
		args+=" build bundle"
	fi

	if [ ${mode} == "release" ]; then
		echo "Build with distclean and compression. Release mode"
		args+=" -tc true build bundle distclean"
	fi

	if [ ${mode} == "headless" ]; then
		echo "Build with distclean and without compression. Headless mode"
		args+=" build bundle distclean"
	fi

	echo -e "\nBuild command: java ${args}"
	java ${args}

	echo ""
}


build() {
	mkdir -p ${version_folder}

	platform=$1
	mode=$2
	additional_params="${build_params} ${settings_params} $3"

	if [ ${mode} == "release" ]; then
		ident=${ios_identity_dist}
		prov=${ios_prov_dist}
		android_keystore=${android_keystore_dist}
		android_keystore_password=${android_keystore_password_dist}
		echo -e "\x1B[32mBuild in Release mode\x1B[0m"
	fi
	if [ ${mode} == "debug" ]; then
		ident=${ios_identity_dev}
		prov=${ios_prov_dev}
		android_keystore=${android_keystore_dev}
		android_keystore_password=${android_keystore_password_dev}
		echo -e "\x1B[31mBuild in Debug mode\x1B[0m"
	fi
	if [ ${mode} == "headless" ]; then
		ident=${ios_identity_dev}
		prov=${ios_prov_dev}
		android_keystore=${android_keystore_dev}
		android_keystore_password=${android_keystore_password_dev}
		echo -e "\x1B[34mBuild in Headless mode\x1B[0m"
	fi

	if $is_resolve; then
		resolve_bob
	fi

	filename="${file_prefix_name}_${mode}"
	is_build_success=true

	# Android platform
	if [ ${platform} == ${android_platform} ]; then
		line="${dist_folder}/${title}/${title}"

		if $is_fast_debug; then
			echo "Build only one platform for faster build"
			additional_params=" -ar armv7-android $additional_params"
		fi

		if $is_live_content; then
			echo "Add publishing live content to build"
			additional_params=" -l yes $additional_params"
		fi

		echo "Start build android ${mode}"
		bob ${mode} -brhtml ${version_folder}/${filename}_android_report.html \
			--platform ${platform} --keystore ${android_keystore} \
			--keystore-pass ${android_keystore_password} --build-server ${build_server} \
			${additional_params}

		mv "${line}.apk" "${version_folder}/${filename}.apk" || is_build_success=false
	fi

	# iOS platform
	if [ ${platform} == ${ios_platform} ]; then
		line="${dist_folder}/${title}"

		echo "Start build ios ${mode}"
		bob ${mode} -brhtml ${version_folder}/${filename}_ios_report.html \
			--platform ${platform} --identity ${ident} -mp ${prov} \
			--build-server ${build_server} ${additional_params}

		rm -rf "${version_folder}/${filename}.app"
		mv "${line}.app" "${version_folder}/${filename}.app"
		mv "${line}.ipa" "${version_folder}/${filename}.ipa" || is_build_success=false
	fi

	# HTML5 platform
	if [ ${platform} == ${html_platform} ]; then
		line="${dist_folder}/${title}"

		echo "Start build HTML5 ${mode}"
		bob ${mode} -brhtml ${version_folder}/${filename}_html_report.html \
			--platform ${platform} ${additional_params}

		rm -rf "${version_folder}/${filename}_html"
		rm -f "${version_folder}/${filename}_html.zip"
		mv "${line}" "${version_folder}/${filename}_html"
		zip "${version_folder}/${filename}_html.zip" -r "${version_folder}/${filename}_html"
	fi

	# Linux platform
	if [ ${platform} == ${linux_platform} ]; then
		line="${dist_folder}/${title}"

		echo "Start build Linux ${mode}"
		bob ${mode} -brhtml ${version_folder}/${filename}_linux_report.html \
			--platform ${platform} ${additional_params}

		rm -rf "${version_folder}/${filename}_linux"
		mv "${line}" "${version_folder}/${filename}_linux" || is_build_success=false
	fi

	# MacOS platform
	if [ ${platform} == ${macos_platform} ]; then
		line="${dist_folder}/${title}.app"

		echo "Start build MacOS ${mode}"
		bob ${mode} -brhtml ${version_folder}/${filename}_linux_report.html \
			--platform ${platform} ${additional_params}

		rm -rf "${version_folder}/${filename}_macos.app"
		mv "${line}" "${version_folder}/${filename}_macos.app" || is_build_success=false
	fi

	# Windows platform
	if [ ${platform} == ${windows_platform} ]; then
		line="${dist_folder}/${title}"

		echo "Start build Windows ${mode}"
		bob ${mode} -brhtml ${version_folder}/${filename}_linux_report.html \
			--platform ${platform} ${additional_params}

		rm -rf "${version_folder}/${filename}_windows"
		mv "${line}" "${version_folder}/${filename}_windows" || is_build_success=false
	fi

	if $is_build_success; then
		echo -e "\x1B[32mSave bundle at ${version_folder}/${filename}\x1B[0m"
	else
		echo -e "\x1B[31mError during building...\x1B[0m"
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

	if [ ${platform} == ${html_platform} ]; then
		filename="${version_folder}/${file_prefix_name}_${mode}_html/"
		echo "Start python server and open in browser ${filename:1}"

		open "http://localhost:8000${filename:1}"
		python --version
		python -m "SimpleHTTPServer"
	fi
}


run() {
	platform=$1
	mode=$2

	if [ ${platform} == ${android_platform} ]; then
		adb shell am start -n ${bundle_id}/com.dynamo.android.DefoldActivity
		adb logcat -s defold
	fi

	if [ ${platform} == ${ios_platform} ]; then
		filename_app="${version_folder}/${file_prefix_name}_${mode}.app"
		ios-deploy -I -m -b ${filename_app} | grep ${title_no_space}
	fi

	if [ ${platform} == ${linux_platform} ]; then
		filename="${version_folder}/${file_prefix_name}_${mode}_linux/${title_no_space}.x86_64"

		echo "Start Linux build: $filename"
		./$filename
	fi

	if [ ${platform} == ${macos_platform} ]; then
		filename="${version_folder}/${file_prefix_name}_${mode}_macos.app"

		echo "Start MacOS build: $filename"
		open $filename
	fi

	if [ ${platform} == ${windows_platform} ]; then
		filename="${version_folder}/${file_prefix_name}_${mode}_windows/${title_no_space}.exe"

		echo "Start Windows build: $filename"
		./$filename
	fi
}


clean() {
	rm -f ${version_settings_filename}
}


### ARGS PARSING
arg=$1
is_build=false
is_deploy=false
is_android=false
is_ios=false
is_html=false
is_linux=false
is_macos=false
is_windows=false
is_resolve=true
is_android_instant=false
is_fast_debug=false
mode="debug"
settings_params=""
build_params=""
build_server=${build_server:-"https://build.defold.com"}

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
	if [ $a == "h" ]; then
		is_html=true
	fi
	if [ $a == "l" ]; then
		is_linux=true
	fi
	if [ $a == "w" ]; then
		is_windows=true
	fi
	if [ $a == "m" ]; then
		is_macos=true
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
		--fast)
			is_fast_debug=true
			is_resolve=false
			shift
		;;
		--no-resolve)
			is_resolve=false
			shift
		;;
		--settings)
			settings_params="${settings_params} --settings $2"
			shift
			shift
		;;
		--param)
			build_params="${build_params} $2"
			shift
			shift
		;;
		--unit-test)
			mode="headless"
			shift
		;;
		*) # Unknown option
			shift
		;;
	esac
done


### Create additional info to settings
echo "[project]
version = ${version}
commit_sha = ${commit_sha}
build_time = ${build_time}" > ${version_settings_filename}
settings_params="${settings_params} --settings ${version_settings_filename}"


### Deployer run
if $is_ios
then
	if $is_build; then
		echo -e "\nStart build on \x1B[36m${ios_platform}\x1B[0m"
		build ${ios_platform} ${mode}
	fi

	if $is_deploy; then
		echo "Start deploy project to device"
		deploy ${ios_platform} ${mode}
		run ${ios_platform} ${mode}
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
			run ${android_platform} ${mode}
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

if $is_html
then
	if $is_build; then
		echo -e "\nStart build on \x1B[33m${html_platform}\x1B[0m"
		build ${html_platform} ${mode}
	fi

	if $is_deploy; then
		deploy ${html_platform} ${mode}
	fi
fi

if $is_linux
then
	if $is_build; then
		echo -e "\nStart build on \x1B[33m${linux_platform}\x1B[0m"
		build ${linux_platform} ${mode}
	fi

	if $is_deploy; then
		run ${linux_platform} ${mode}
	fi
fi

if $is_macos
then
	if $is_build; then
		echo -e "\nStart build on \x1B[33m${macos_platform}\x1B[0m"
		build ${macos_platform} ${mode}
	fi

	if $is_deploy; then
		run ${macos_platform} ${mode}
	fi
fi

if $is_windows
then
	if $is_build; then
		echo -e "\nStart build on \x1B[33m${windows_platform}\x1B[0m"
		build ${windows_platform} ${mode}
	fi

	if $is_deploy; then
		run ${windows_platform} ${mode}
	fi
fi

echo -e "\nDeployer end"
