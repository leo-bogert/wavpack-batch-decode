#!/bin/bash
if ! source "lib-bash-leo.sh" ; then
	echo 'lib-bash-leo.sh is missing in PATH!'
	exit 1
fi

shopt -u failglob	# some directories which we receive might not contain wavpacks so we disable it.

INPUT_DIR_ABSOLUTE=''
OUTPUT_DIR_ABSOLUTE=''

unpack() {
	local album
	album="$(basename "$1")"
	stdout "Unpacking: $album"

	cp -a --no-clobber -- "$1" "$OUTPUT_DIR_ABSOLUTE"

	set_working_directory_or_die "$OUTPUT_DIR_ABSOLUTE/$album"
	for wavpack in *.wv ; do
		local disc
		disc="$(basename "$wavpack" ".wv")"

		if [[ -e "${disc}.cue" || -e "${disc}.log" || -e "${disc}.wav" ]] ; then
			die "cue, log or wav exists already for: $wavpack"
		fi

		local log_utf8="$disc.log.utf8"
		wvunpack -cc -d -m --no-utf8-convert -q -xx "LOG=$log_utf8" "$wavpack"
		# perfect-flac-encode expects UTF-16 on the LOG because it is the standard format which EAC will spit out, so we convert to that.
		iconv --from-code utf-8 --to-code utf-16 --output "$disc.log" "$log_utf8"
		rm -- "$log_utf8"
	done
}

unpack_all() {
	for album in "$INPUT_DIR_ABSOLUTE"/* ; do
		stdout ""
		stdout ""

		if ! [ -d "$album" ] ; then
			stderr "Skipping non-directory: $album"
			continue
		fi
		
		local -a wavpacks=( "$album"/*.wv )

		if (( ${#wavpacks[@]} > 0 )) ; then
			unpack "$album"
		elif [ "$(find "$album" -iname '*.wv' -printf '1' -quit)" = '1' ] ; then
			die "Found Wavpacks in subdirectories or with uppercase file extension, please move them to the parent directory and fix their file extension: $album"
		else
			stdout "No Wavpacks in: $album"
		fi
	done
}

main() {
	obtain_two_parameters_as_inputdir_output_dir "$@"

	if [ -e "$OUTPUT_DIR_ABSOLUTE" ] ; then
		die "Output dir exists already!"
	fi
	mkdir -p -- "$OUTPUT_DIR_ABSOLUTE"

	unpack_all

	echo "SUCCESS."
	exit 0 # SUCCESS
}

main "$@"
