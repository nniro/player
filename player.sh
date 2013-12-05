#! /bin/bash

# digital (mp3/ogg/wav) music player
alsaplayer="alsaplayer -o jack -i text -q"
# midi music player
timidity="timidity"
# video/movie player
mplayer="mplayer -vo null -quiet"
# amiga modules music player
mikmod="mikmod -p 0 -q"

# speech synthesizer program
speak="sh $HOME/bin/speak.sh"

#

# the two following functions are generated from createConv.sh
toHtmlEnc () {
sed -e "s/ /%20/g; s/\!/%21/g; s/\"/%22/g; s/#/%23/g; s/\\$/%24/g; s/&/%26/g; s/'/%27/g; s/(/%28/g; s/)/%29/g; s/\*/%2a/g; s/+/%2b/g; s/\,/%2c/g; s/\./%2e/g; s/\//%2f/g;" -e "s/:/%3a/g; s/;/%3b/g; s/</%3c/g; s/>/%3e/g; s/?/%3f/g;" -e "s/\[/%5b/g; s/\\\\/%5c/g; s/\]/%5d/g; s/\^/%5e/g; s/_/%5f/g; s/\`/%60/g;" -e "s/{/%7b/g; s/|/%7c/g; s/}/%7d/g; s/~/%7e/g; s//%7f/g;"
}

# see the message before toHtmlEnc
fromHtmlEnc () {
sed -e "s/%20/ /g; s/%21/\!/g; s/%22/\"/g; s/%23/#/g; s/%24/\\$/g; s/%26/&/g; s/%27/'/g; s/%28/(/g; s/%29/)/g; s/%2a/\*/g; s/%2b/+/g; s/%2c/\,/g; s/%2e/\./g; s/%2f/\//g;" -e "s/%3a/:/g; s/%3b/;/g; s/%3c/</g; s/%3e/>/g; s/%3f/?/g;" -e "s/%5b/\[/g; s/%5c/\\\\/g; s/%5d/\]/g; s/%5e/\^/g; s/%5f/_/g; s/%60/\`/g;" -e "s/%7b/{/g; s/%7c/|/g; s/%7d/}/g; s/%7e/~/g; s/%7f//g;"
}

# this adds support for the standard GNU argument system where
# long options like --test need the character `=' to pass values.
# and also replaces spaces by %20
fixArg () {
	local result=""
	while [ "$1" != "" ]; do
		tmp=""
		result="$result `echo \"$1\" | toHtmlEnc | sed 's/=/ /g'`"
		shift 1
	done
	echo $result
}
set -- `fixArg "$@"`

tempDir="/tmp/player.sh"

showHelp () {
	printf "player.sh [OPTIONS] ... [FILES]\n"
	printf "	High order music player.\n"
	printf "	Plays various music files transparently.\n"
	printf "	Includes compressed directories support and recursion.\n"
	echo
	printf "	-h,--help	This help\n"
	printf "	-s,--shuffle	shuffle the playlist\n"
	printf "	-l,--loop	loops the playlist\n"
	printf "	-r,--recursive	recursively handle directories\n"
	printf "	-y,--speak	use eSpeak to transmit messages\n"
	printf "	-f,--filter	regex for files to exclude\n"
	printf "	-q,--quiet	quiet mode\n"
	echo
	printf "	A special format can be used to access specific\n"
	printf "	files inside compressed files.\n"
	echo
	printf "	Here's the format :\n"
	printf "	@<PATH>@<COMPRESSED FILE>@<INSIDER FILE>\n"
	echo
	printf "	PATH :	paths, either absolute or relative, use \`./'\n"
	printf "		for the current directory (mandatory).\n"
	printf "	INSIDER FILE :	Full path of the file inside the\n"
	printf "			compressed file.\n"
	printf "	NOTE :	for doing spaces, use \`\ '.\n"
	printf "		single and double quotes are not supported.\n"
	echo
}

basename2 () {
	local input=$1
	if [ "$input" == "-" ]; then
		input=`cat /dev/stdin`
	fi
	basename "$input"
}

# loop files in a compressed file
loopFilesComp () {
	local recursive=$1

	shift 1

	local file="`echo $1 | fromHtmlEnc`"

	local files=""
	local path=""
	local comprF=""
	case `echo $1 | fromHtmlEnc | sed 's/.*\(tar.gz\|tar.bz2\|tar.xz\|zip\|rar\)/\1/'` in
		tar.gz) #echo a bzip compressed file
			local files=`gzip -cd "$file" | tar -t | toHtmlEnc`
			local path=`dirname "$file"`
			local comprF=`basename "$file"`
		;;

		tar.bz2) #echo a bzip2 compressed file
			local files=`bzip2 -cdk "$file" | tar -t | toHtmlEnc`
			local path=`dirname "$file"`
			local comprF=`basename "$file"`
		;;

		tar.xz) #echo a xz compressed file
			local files=`xz -cdk "$file" | tar -t | toHtmlEnc`
			local path=`dirname "$file"`
			local comprF=`basename "$file"`
		;;

		zip) #echo a zip compressed file
			local files=`unzip -qq -l "$file" | sed -e 's/^ *[^ ]* *[^ ]* *[^ ]* *//' | toHtmlEnc`
			local path=`dirname "$file"`
			local comprF=`basename "$file"`
		;;

		rar) #echo a rar compressed file
			local files=`unrar lb "$file" | toHtmlEnc`
			local path=`dirname "$file"`
			local comprF=`basename "$file"`
		;;

		*) #echo not a compressed directory file
			exit 0
		;;
	esac

	local path="`echo $path | toHtmlEnc`"
	local comprF="`echo $comprF | toHtmlEnc`"

	# first step : filter only directories
	#echo $files | sed '/.*\/$/ \! d'
	local parent_dir="./"

	# delete all directories (the content of the dirs are kept though)
	local tmp=""
	for i in $files; do
		local tmp="$tmp `echo $i | sed \"/.*\`echo / | toHtmlEnc\`$/ d\"`"
	done
	local files="$tmp"

	if [ "$parent_dir" == " " ] || [ "$parent_dir" == "" ]; then
		local parent_dir="./"
	fi

	# second step : filter all the files and directories not in the parent
	#		directory if recursion is not activated.
	files2=""
	for i in $files; do
		local curparrent="`dirname \"\`echo $i | fromHtmlEnc \`\"`/"
		if [ "$recursive" == "1" ] || [ "$curparrent" == $parent_dir ]; then
			#echo "-->" $i
			local files2="$files2 @$path/@$comprF@$i"
		fi
	done

	echo $files2
}

getComprFile () {
	if [ ! -e $tempDir ]; then
		mkdir $tempDir
	fi

	declare -a comp=(`echo $1 | sed 's/^@// ; s/@/ /g'`)

	if [ "${comp[2]}" != "1" ] && [ "`echo ${comp[2]} | sed 's/.*\/$/1/'`" == "1" ]; then
		# this is a directory, we don't handle that
		exit 0
	fi

	local opwd=$PWD
	comp[0]="`echo ${comp[0]} | fromHtmlEnc`"
	comp[1]="`echo ${comp[1]} | fromHtmlEnc`"

	# handles both relative and absolute paths
	if [ "${comp[0]:0:1}" == "/" ]; then
		local base=""
	else
		local base="$opwd/"
	fi

	cd $tempDir

	local tmp="`echo ${comp[2]} | fromHtmlEnc`"

	case `echo ${comp[1]} | sed 's/.*\(tar.gz\|tar.bz2\|tar.xz\|zip\|rar\)/\1/'` in
		tar.gz) #echo a bzip compressed file
			tar -zxf ${base}${comp[0]}"${comp[1]}" "$tmp"
		;;

		tar.bz2) #echo a bzip2 compressed file
			tar -jxf ${base}${comp[0]}"${comp[1]}" "$tmp"
		;;

		tar.xz) #echo a xz compressed file
			xz -cdk ${base}${comp[0]}"${comp[1]}" | tar /dev/stdin "$tmp"
		;;

		zip) #echo a zip compressed file
			# fixes the `[' character for which unzip is
			# particularly picky (note : only `[', not `]')
			local tmp="`echo $tmp | sed 's/\[/\\\[/g'`"
			unzip -qq ${base}${comp[0]}"${comp[1]}" "$tmp"
		;;

		rar) #echo a rar compressed file
			# special format, files are not preceded by ./
			tmp2="`echo $tmp | sed 's/^\.\///'`"
			unrar x ${base}${comp[0]}"${comp[1]}" "$tmp2" > /dev/null 2> /dev/null
		;;

		*) #echo not a compressed directory file
			exit 0
		;;
	esac

	cd $opwd

	echo ${tempDir}/${comp[2]}
}

loopFiles () {
	local _result=""
	local recursive=$1

	shift 1

	while [ 1 -eq 1 ]; do
		if [ "$1" == "" ]; then
			break
		fi

		# fixes files containing spaces until they
		# are later converted to %20
		local processed=`echo "$1" | sed 's/\([^\\]\) /\1\\ /g'`

		if [ "$recursive" == "1" ]; then
			local _result="$_result `preparePath \"$processed\" 1`"
		else
			local _result="$_result `preparePath \"$processed\" 2`"
		fi

		shift 1
	done

	echo $_result
}

preparePath () {
	local tmp="`echo $1 | fromHtmlEnc`"
	case `echo $tmp | sed 's/.*\(tar.gz\|tar.bz2\|tar.xz\|zip\|rar\)/\1/'` in

		tar.gz|tar.bz2|tar.xz|zip|rar)
			local result=`loopFilesComp "$2" "$1"`
		;;

		*)
				# we change any in file spaces to %20 
				# to prepare the file entries to be used
			if [ -d "$tmp" ] && [ "$2" != "2" ]; then
				local result=`loopFiles "$2" $tmp/*`
			elif [ ! -d "$tmp" ]; then
			       	local result="`echo $1 | toHtmlEnc`"
			fi
		;;
	esac

	echo $result
}

music=""
shuffle=0
loop=0
recurse=0
espeak=0
filter=""
quiet=0

message () {
	local message=$1
	local noOutput=$2
	if [ $quiet == 0 ] || [ "$noOutput" == "" ]; then
		echo $message
	fi

	if [ $espeak == 1 ]; then
		$speak "$message" > $tmpDir/message.wav
		$alsaplayer $tmpDir/message.wav 2> /dev/null 1> /dev/null
	fi
}

#create music list from input
while [ 1 -eq 1 ]; do
	if [ "$1" == "" ]; then
		break
	fi

	case $1 in
		-h|--help)
			showHelp
			exit 0
		;;

		-s|--shuffle)
			shuffle=1
		;;

		-l|--loop)
			loop=1
		;;

		-r|--recursive)
			recurse=1
		;;

		-y|--speak)
			espeak=1
		;;

		-f|--filter)
			shift 1
			filter=`echo $1 | fromHtmlEnc`
		;;

		-q|--quiet)
			quiet=1
		;;

		-*|--*)
			echo "Ignoring Invalid Option \`$1'"
		;;

		*)
			if [ "$saidPreparingPlaylist" == "" ]; then
				message "Preparing playlist..." $quiet
				saidPreparingPlaylist=1
			fi

			if [ $recurse == 1 ]; then
				music="${music} `preparePath \"$1\" 1`"
			else
				music="${music} `preparePath \"$1\"`"
			fi
		;;
	esac

	shift 1
done

if [ "$music" == "" ]; then
	showHelp
	exit 0
fi


if [ "$filter" != "" ]; then
	music=`echo $music | sed 's/ /\n/g' | sed -n "/$filter/! p"`
fi
#exit 0

progExit () {
	if [ $quiet == 0 ]; then
		echo "Exiting player.sh"
	fi

	if [ -e $tempDir ]; then
		rm -Rf $tempDir
	fi
	exit 0
}

trap progExit SIGINT

randomnizePlaylist () {
	declare -a array=($@)
	local len=${#array[@]}
	declare -a result

	local i=0
	while [ $i -lt $len ]; do
		local pick=$((RANDOM % $len))

		while [ 1 -ne 2 ]; do
			if [ ! ${result[$pick]} ]; then
				result[$pick]=${array[$i]}
				break
		       fi
			local pick=$(((pick + 1) % $len))
		done

		local i=$((i + 1))
	done

	echo ${result[@]}
}

play_midi () {
	local song=`echo $1 | fromHtmlEnc`
	$timidity "$song" > /dev/null 2> /dev/null
}

play_digital () {
	local song=`echo $1 | fromHtmlEnc`
	$alsaplayer "$song" > /dev/null 2> /dev/null
}

play_mod () {
	local song=`echo $1 | fromHtmlEnc`
	$mikmod "$song"
}

play_video () {
	local song=`echo $1 | fromHtmlEnc`
	$mplayer "$song" > /dev/null 2> /dev/null
}

announce () {
	local song=$1
	local stype=$2
	if [ $quiet == 0 ]; then
		echo now playing $stype music file : `echo "$song" | fromHtmlEnc`
	fi
	if [ $espeak == 1 ]; then
		$speak "now playing $stype music file : `echo "$song" | fromHtmlEnc | basename2 -`" > $tmpDir/message.wav
		$alsaplayer $tmpDir/message.wav 2> /dev/null 1> /dev/null &
	fi
}

# pretty path for compressed directories (harmless for other formats)
prettyPath () {
	echo `echo $1 | sed 's/^@\(.*\)@\(.*\)@\(.*\)$/\1\2\/\3/'`
}

play_song () {
	local song=$1
	shift 1
	local list=$@
	local songPath=$song
	local compressed=0
	local inComp=0 # inside a compressed file

	# compressed directory support :D
	if [ "$song" != "1" ] && [ "`echo $song | sed 's/^@.*/1/'`" == "1" ]; then
		local inComp=1
		local songPath=`prettyPath "$song"`
		local song=`getComprFile "$song"`
	fi

	# check for compression extention
	case `echo $song | sed 's/[^\.]*\.//g'` in
		gz|bz2|zip)
			local compressed=1
			local song1=`echo $song | sed 's/\(.*\)\(\.gz\|\.bz2\|\.zip\)$/\1/'`
		;;

		*) local song1=$song
		;;
	esac

	case `echo $song1 | fromHtmlEnc | sed 's/[^\.]*\.//g' | sed 's/\(.*\)/\L\1\E/'` in
		mp3|ogg|wav)
			if [ $compressed -eq 1 ]; then
				message "compressed file format not supported" $quiet
			else
				announce "$songPath" "digital"
				play_digital "$song"
			fi
		;;

		flv|wma)
			if [ $compressed -eq 1 ]; then
				message "compressed file format not supported" $quiet
			else
				announce "$songPath" "video"
				play_video "$song"
			fi
		;;

		mid|midi)
			if [ $compressed -eq 1 ]; then
				message "compressed file format not supported" $quiet
			else
				announce "$songPath" "midi"
				play_midi "$song"
			fi
		;;

		mod|xm|s3m|it|mtm)
			# supports compressed files transparently
			announce "$songPath" "amiga"
			play_mod "$song"
		;;

		*)
			message "unhandled music format : `basename $songPath | fromHtmlEnc`" $quiet
		;;
	esac

	if [ $inComp == 1 ]; then
		rm -f "`echo $song | fromHtmlEnc`"
	fi

	[ ! "$list" == "" ] && play_song $list
}

playPlaylist () {
	if [ "`echo $@ | sed 's/^ *$//'`" == "" ]; then
		message "Playlist is empty, maybe you forgot to use the recursive (-r or --recursive) argument?" $quiet
		exit 1
	fi

	if [ $shuffle == 1 ]; then
		declare -a playlist=(`randomnizePlaylist "$@"`)
	else
		declare -a playlist=("$@")
	fi

	play_song "${playlist[@]}"

	if [ $loop = 1 ]; then
		playPlaylist "${playlist[@]}"
	fi
}

playPlaylist "$music"

progExit
