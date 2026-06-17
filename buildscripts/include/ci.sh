#!/bin/bash -e

# go to buildscripts root folder
cd "$( dirname "${BASH_SOURCE[0]}" )/.."

. ./include/depinfo.sh

msg() {
	printf '==> %s\n' "$1"
}

fetch_prefix() {
	if [[ "$CACHE_MODE" == folder ]]; then
		local text=
		if [ -f "$CACHE_FOLDER/id.txt" ]; then
			text=$(cat "$CACHE_FOLDER/id.txt")
		else
			echo "Cache seems to be empty"
		fi
		printf 'Expecting "%s",\nfound     "%s".\n' "$ci_tarball-$1" "$text"
		if [[ "$text" == "$ci_tarball-$1" ]]; then
			tar -xzf "$CACHE_FOLDER/data.tgz" -C prefix && return 0
		fi
	fi
	return 1
}

build_prefix() {
	msg "Building the prefix ($ci_tarball-$2)..."

	msg "Fetching deps"
	IN_CI=1 ./include/download-deps.sh

	msg "Compiling for $2"
	./buildall.sh --arch "$2" --only-deps mpv

	if [[ "$CACHE_MODE" == folder && -w "$CACHE_FOLDER" ]]; then
		msg "Compressing the prefix"
		tar -cvzf "$CACHE_FOLDER/data.tgz" -C prefix .
		echo "$ci_tarball-$2" >"$CACHE_FOLDER/id.txt"
	fi
}

export WGET="wget --progress=bar:force"

if [ "$1" = "export" ]; then
	# export variable with unique cache identifier
	echo "CACHE_IDENTIFIER=$ci_tarball"
	exit 0
elif [ "$1" = "install" ]; then
	# install deps
	if [[ -n "$ANDROID_HOME" && -d "$ANDROID_HOME" ]]; then
		msg "Linking existing SDK"
		mkdir -p sdk
		ln -sv "$ANDROID_HOME" sdk/android-sdk-linux
	fi

	msg "Fetching SDK + NDK"
	IN_CI=1 ./include/download-sdk.sh

	msg "Fetching mpv"
	mkdir -p deps/mpv
	$WGET https://github.com/mpv-player/mpv/archive/master.tar.gz -O master.tgz
	tar -xzf master.tgz -C deps/mpv --strip-components=1
	rm master.tgz

	msg "Trying to fetch existing prefix for $2"
	mkdir -p prefix
	fetch_prefix "$2" || build_prefix "$1" "$2"
	exit 0
elif [ "$1" = "build" ]; then
	msg "Building mpv for $2"
	./buildall.sh --arch "$2" -n mpv || {
		# show logfile if configure failed
		[ ! -f deps/mpv/_build_$2/config.h ] && \
			cat deps/mpv/_build_$2/meson-logs/meson-log.txt
		exit 1
	}

	msg "Building mpv-android for $2"
	./buildall.sh --arch "$2" -n
	exit 0
else
	exit 1
fi
