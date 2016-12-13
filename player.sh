#! /bin/sh

#The MIT License (MIT)
#
#Copyright (c) 2010-2016 Nicholas Niro
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.


# midi music player
#timidity="timidity"
timidity="aplaymidi -p 17"
# video/movie player
mplayer="mplayer -vo null -quiet"
# amiga modules music player
#mikmod="mikmod -p 0 -q"
mikmod="timidity"
# digital (mp3/ogg/wav) music player
#alsaplayer="alsaplayer -i text -q"
alsaplayer=$mplayer

debugging=0

case "`readlink -f /proc/$$/exe`" in
	*zsh)
		# we need arrays to start at 0 in zsh
		setopt ksharrays
	;;

	*)
	;;
esac

function mkTuple() {
	# using '@' characters to support the content even if they contain commas inside of them
	# now if the content contains '@', we are screwed so we encode both '@' characters and ','
	# characters.
	first=`echo "$1" | sed -e 's/\@/%40/g; s/,/%2c/g'`
	second=`echo "$2" | sed -e 's/\@/%40/g; s/,/%2c/g'`
	echo "(@$first@,@$second@)"
}

function isTuple() {
	if [[ "`echo \"$1\" | sed -e 's/^(\@[^\@]*\@,\@[^\@]*\@)$//'`" == "" ]]; then
		echo 1
	else
		echo 0
	fi
}

# output the first element of a tuple
function fst() {
	if [[ `isTuple "$1"` == 0 ]]; then
		echo "Input is not a tuple"
		exit 1
	fi
	echo "$1" | sed -e 's/(\@\(.*\)\@,\@.*\@)/\1/' | sed -e 's/%40/\@/g; s/%2c/,/g'
}

# output the second element of a tuple
function snd() {
	if [[ `isTuple "$1"` == 0 ]]; then
		echo "Input is not a tuple"
		exit 1
	fi
	echo "$1" | sed -e 's/(\@[^\@]*\@,\@\([^\@]*\)\@)/\1/' | sed -e 's/%40/\@/g; s/%2c/,/g'
}

function sep() {
	if [[ "$2" == "" ]]; then
		local sepChr=" "
		local data="$1"
	else
		local sepChr="$1"
		local data="$2"
	fi
	mkTuple "`echo \"$data\" | sed -e \"s/^\([^$sepChr]*\)\($sepChr\)\(.*\)$/\1/\"`" "`echo \"$data\" | sed -ne \"s/^\([^$sepChr]*\)$sepChr\(.*\)$/\2/ p\"`"
}

# speech synthesizer program
speak="sh $HOME/bin/speak.sh --stdout"

# the two following functions are generated from createConv.sh
toHtmlEnc () {
sed -e "s/ /%20/g; s/\!/%21/g; s/\"/%22/g; s/#/%23/g; s/\\$/%24/g; s/&/%26/g; s/'/%27/g; s/(/%28/g; s/)/%29/g; s/\*/%2a/g; s/+/%2b/g; s/\,/%2c/g; s/\./%2e/g; s/\//%2f/g;" -e "s/:/%3a/g; s/;/%3b/g; s/</%3c/g; s/>/%3e/g; s/?/%3f/g;" -e "s/\[/%5b/g; s/\\\\/%5c/g; s/\]/%5d/g; s/\^/%5e/g; s/_/%5f/g; s/\`/%60/g;" -e "s/{/%7b/g; s/|/%7c/g; s/}/%7d/g; s/~/%7e/g; s//%7f/g;"
}

# see the message before toHtmlEnc
fromHtmlEnc () {
sed -e "s/%20/ /g; s/%21/\!/g; s/%22/\"/g; s/%23/#/g; s/%24/\\$/g; s/%26/\&/g; s/%27/'/g; s/%28/(/g; s/%29/)/g; s/%2a/\*/g; s/%2b/+/g; s/%2c/\,/g; s/%2e/\./g; s/%2f/\//g;" -e "s/%3a/:/g; s/%3b/;/g; s/%3c/</g; s/%3e/>/g; s/%3f/?/g;" -e "s/%5b/\[/g; s/%5c/\\\\/g; s/%5d/\]/g; s/%5e/\^/g; s/%5f/_/g; s/%60/\`/g;" -e "s/%7b/{/g; s/%7c/|/g; s/%7d/}/g; s/%7e/~/g; s/%7f//g;"
}

# this adds support for the standard GNU argument system where
# long options like --test need the character `=' to pass values.
# and also replaces spaces by %20
fixArg () {
	local result=""
	while [[ "$1" != "" ]]; do
		tmp=""
		result="$result `echo \"$1\" | toHtmlEnc | sed 's/=/ /g'`"
		shift 1
	done
	echo $result
}
set -- `fixArg "$@"`

tempDir="/tmp/player.sh"
debugPath="/tmp/player.sh.debug"

[[ $debugging == 1 ]] && if [[ -e $debugPath ]]; then rm $debugPath; fi && touch $debugPath

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
	if [[ "$input" == "-" ]]; then
		input=`cat /dev/stdin`
	fi
	basename "$input"
}

fixSpaces () {
	echo "`echo "$1" | sed 's/\([^\\]\) /\1\\\\ /g'`"
}

# loop files in a compressed file
loopFilesComp () {
	local recursive=$1

	shift 1

	local file="`echo $1 | fromHtmlEnc | sed -e 's/^ \(.*\)/\1/'`"

	local files=""
	local cPath=""
	local comprF=""

	[[ $debugging == 1 ]] && echo "archive checker : $file" >> $debugPath

	case `echo $1 | fromHtmlEnc | sed -e 's/.*\(tar.gz\|tar.bz2\|tar.xz\|zip\|rar\)/\1/'` in
		tar.gz) #echo a bzip compressed file
			local files="`gzip -cd \"$file\" | tar -t | toHtmlEnc`"
			local cPath="`dirname \"$file\"`"
			local comprF="`basename \"$file\"`"
		;;

		tar.bz2) #echo a bzip2 compressed file
			local files="`bzip2 -cdk \"$file\" | tar -t | toHtmlEnc`"
			local cPath="`dirname \"$file\"`"
			local comprF="`basename \"$file\"`"
		;;

		tar.xz) #echo a xz compressed file
			local files="`xz -cdk \"$file\" | tar -t | toHtmlEnc`"
			local cPath="`dirname \"$file\"`"
			local comprF="`basename \"$file\"`"
		;;

		zip) #echo a zip compressed file
			[[ $debugging == 1 ]] && echo "archive is zip compressed" >> $debugPath
			local files="`unzip -qq -l \"$file\" | sed -e 's/^ *[^ ]* *[^ ]* *[^ ]* *//' | toHtmlEnc`"
			local cPath="`dirname \"$file\"`"
			local comprF="`basename \"$file\"`"
		;;

		rar) #echo a rar compressed file
			[[ $debugging == 1 ]] && echo "archive is rar compressed" >> $debugPath
			local files="`unrar vb \"$file\" | toHtmlEnc`"
			local cPath="`dirname \"$file\"`"
			local comprF="`basename \"$file\"`"
			[[ $debugging == 1 ]] && echo "After getting all the content of the compressed file" >> $debugPath
		;;

		*) #echo not a compressed directory file or unhandled
			[[ $debugging == 1 ]] && echo "not a compressed directory" >> $debugPath
			exit 0
		;;
	esac

	local cPath="`echo $cPath | toHtmlEnc`"
	local comprF="`echo $comprF | toHtmlEnc`"

	# first step : filter only directories
	#echo $files | sed '/.*\/$/ \! d'
	local parent_dir="./"
#	for i in $files; do
#		local parent_dir="$parent_dir `echo $i | sed '/.*\/$/! d'`"
#		break
#	done

	# convert the files : remove any newlines
	files="`echo $files | sed -n -e 'H; $ b e' -e 'b; : e {x; s/\n/ /g ; p ; q}' | sed -e '1 s/^ *\(.*\)/\1/'`"

	[[ $debugging == 1 ]] && echo "files in archive : $files" >> $debugPath

	# delete all directories (the content of the dirs are kept though)
	local tmp=""
	#for i in $files; do
	#	local tmp="$tmp `echo $i | sed -e \"/.*\`echo / | toHtmlEnc\`$/ d\"`"
	#done

	#echo " archive files without directories : $tmp" >> $debugPath

	#local files="$tmp"

	if [[ "$parent_dir" == " " ]] || [[ "$parent_dir" == "" ]]; then
		local parent_dir="./"
	fi

	#echo $parent_dir

	# second step : filter all the files and directories not in the parent
	#		directory if recursion is not activated.
	local files2=""
	#for i in "$files"; do
		#local curparrent="`dirname \"\`echo $i | fromHtmlEnc \`\"`/"
		# echo $i -- $curparrent -- \"$parent_dir\"
		#if [[ "$recursive" == "1" ]] || [[ "$curparrent" == $parent_dir ]]; then
			#echo "-->" $i
#			if [[ "$files2" != "" ]]; then
#				local files2="$files2 @$cPath/@$comprF@$i"
#			else
#				local files2="@$cPath/@$comprF@$i"
#			fi
		#fi
	#done

	myTuple="`mkTuple \" \" \"$files\"`"
	[[ $debugging == 1 ]] && echo "convertion tuple : [isTuple? `isTuple \"$myTuple\"`] \"$myTuple\"" >> $debugPath
	while [[ "`snd \"$myTuple\"`" != "" ]]; do
		x="`fst \"$myTuple\"`"
		xs="`snd \"$myTuple\"`"

		if [[ "$x" != " " ]] && [[ "$x" != "" ]]; then
			if [[ "$files2" != "" ]]; then
				local files2="$files2 @$cPath/@$comprF@$x"
			else
				local files2="@$cPath/@$comprF@$x"
			fi
		fi

		myTuple="`sep \" \" \"$xs\"`"
		[[ $debugging == 1 ]] && echo "loop data : x: \"$x\" xs: \"$xs\"" >> $debugPath
		[[ $debugging == 1 ]] && echo "Current tuple : \"$myTuple\"" >> $debugPath
		[[ $debugging == 1 ]] && echo "Current files2 result : $files2" >> $debugPath
	done

	[[ $debugging == 1 ]] && echo "archive conv result : $files2" >> $debugPath
	echo $files2
}

getComprFile () {
	if [[ ! -e $tempDir ]]; then
		mkdir $tempDir
	fi

	typeset -a comp
	comp=(`echo $1 | sed 's/^@// ; s/@/ /g'`)

	if [[ "${comp[2]}" != "1" ]] && [[ "`echo ${comp[2]} | sed 's/.*\/$/1/'`" == "1" ]]; then
		# this is a directory, we don't handle that
		exit 0
	fi


	local opwd="$PWD"
	comp[0]="`echo ${comp[0]} | fromHtmlEnc`"
	comp[1]="`echo ${comp[1]} | fromHtmlEnc`"

	# handles both relative and absolute paths
	if [[ "${comp[0]:0:1}" == "/" ]]; then
		local base=""
	else
		local base="$opwd/"
	fi

	cd $tempDir

	local tmp="`echo ${comp[2]} | fromHtmlEnc`"

	case `echo ${comp[1]} | sed 's/.*\(tar.gz\|tar.bz2\|tar.xz\|zip\|rar\)/\1/'` in
		tar.gz) #echo a bzip compressed file
			tar -zxf "${base}${comp[0]}${comp[1]}" "$tmp"
		;;

		tar.bz2) #echo a bzip2 compressed file
			tar -jxf "${base}${comp[0]}${comp[1]}" "$tmp"
		;;

		tar.xz) #echo a xz compressed file
			xz -cdk "${base}${comp[0]}${comp[1]}" | tar -xf /dev/stdin "$tmp"
		;;

		zip) #echo a zip compressed file
			# fixes the `[' character for which unzip is
			# particularly picky (note : only `[', not `]')
			local tmp="`echo $tmp | sed 's/\[/\\\[/g'`"
			unzip -qq "${base}${comp[0]}${comp[1]}" "$tmp"
		;;

		rar) #echo a rar compressed file
			# special format, files are not preceded by ./
			tmp2="`echo $tmp | sed 's/^\.\///'`"
			unrar x "${base}${comp[0]}${comp[1]}" "$tmp2" > /dev/null 2> /dev/null
		;;

		*) #echo not a compressed directory file
			exit 0
		;;
	esac

	cd "$opwd"

	echo ${tempDir}/${comp[2]}
}

preparePath () {
	local recursive=$2
	local tmp="`echo \"$1\" | fromHtmlEnc`"
	[[ $debugging == 1 ]] && echo "preparePath (recursive == $recurse) for : $tmp" >> $debugPath
	case `echo "$tmp" | sed -e 's/.*\(tar.gz\|tar.bz2\|tar.xz\|zip\|rar\)/\1/'` in

		tar.gz|tar.bz2|tar.xz|zip|rar)
			[[ $debugging == 1 ]] && echo "About to recurse compressed file : $tmp" >> $debugPath
			local result="`loopFilesComp \"$2\" \"$1\"`"
		;;

		*)
			if [[ -d "$tmp" ]] && [[ "$recursive" == "1" ]]; then
				# recursive version
				[[ $debugging == 1 ]] && echo "About to recurse the directory : $tmp" >> $debugPath

				result="`find \"$tmp/\" -type f -or -type l | toHtmlEnc`" # | read -r -d '' fResult
			elif [[ ! -d "$tmp" ]]; then
				[[ $debugging == 1 ]] && echo "preparePath : treating as file : $tmp" >> $debugPath
			       	local result="`echo \"$1\" | toHtmlEnc`"
			else
				[[ $debugging == 1 ]] && echo "preparePath : Unknown file type : $tmp" >> $debugPath
			fi
		;;
	esac

	echo $result
}

#preparePath "$1" 1

#houba=`preparePath $1`

#echo Houba : $houba

#exit 0

typeset -a music

#music=()
shuffle=0
loop=0
recurse=0
espeak=0
filter=""
quiet=0

message () {
	local message="$1"
	local noOutput=$2
	if [[ $quiet == 0 ]] || [[ "$noOutput" == "" ]]; then
		echo "$message"
	fi

	if [[ $espeak == 1 ]]; then
		if [[ ! -e $tempDir ]]; then
			mkdir $tempDir
		fi
		local speakCmd="$speak \"$message\" > $tempDir/message.wav"
		local cmd="$alsaplayer \"$tempDir/message.wav\" 2> /dev/null 1> /dev/null"

		eval $speakCmd
		eval $cmd
	fi
}

#create music list from input
while [[ 1 -eq 1 ]]; do
	[[ $debugging == 1 ]] && echo "Parameter loop cycle" >> $debugPath
	if [[ "$1" == "" ]]; then
		[[ $debugging == 1 ]] && echo "broke free of the parameter loop" >> $debugPath
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
			#message "Preparing playlist..." 1
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
			if [[ "$saidPreparingPlaylist" == "" ]]; then
				message "Preparing playlist..." $quiet
				saidPreparingPlaylist=1
			fi

			music[$[${#music[@]} + 1]]="`preparePath \"$1\" $recurse`"

			[[ $debugging == 1 ]] && echo "file added to the list" >> $debugPath
		;;
	esac

	shift 1
done

if [[ ${#music[@]} == 0 ]]; then
	showHelp
	exit 0
fi

#echo $music
#exit 0

music=(`echo ${music[@]} | sed -e 's/\"//g'`)

if [[ "$filter" != "" ]]; then
	music=`echo ${music[@]} | sed 's/ /\n/g' | sed -n "/$filter/! p"`
fi
#echo filtered $music
#exit 0

soundCmdPID=-1

progExit () {
	if [[ $quiet == 0 ]]; then
		echo "Exiting player.sh"
	fi

	if [ $soundCmdPID != -1 ]; then
		#echo "killing soundCmd at PID : $soundCmdPID"
		kill -9 $soundCmdPID
	fi

	if [[ -e $tempDir ]]; then
		rm -Rf $tempDir
	fi
	exit 0
}

trap progExit SIGINT SIGTERM

randomnizePlaylist () {
	typeset -a array
	array=($@)
	local len=${#array[@]}
	typeset -a result

	local i=0
	while [[ $i -lt $len ]]; do
		local pick=$((RANDOM % $len))

		while [[ 1 -ne 2 ]]; do
			if [[ ! ${result[$pick]} ]]; then
				result[$pick]=${array[$i]}
				break
		       fi
			local pick=$(((pick + 1) % $len))
		done

		local i=$((i + 1))
	done

	echo ${result[@]}
}

randomnizePlaylist2 () {
	#typeset -a array
	#array=($@)
	#local len=${#array[@]}
	typeset -a result
	result=($@)
	local len=${#result[@]}

	local i=0
	while [[ $i -lt $len ]]; do
		local pick=$((RANDOM % $len))
		[[ $debugging == 1 ]] && echo "switching #$pick [${result[$pick]}] with $i [${result[$i]}]" >> $debugPath

		# switch the 2
		local temp=${result[$pick]}
		result[$pick]=${result[$i]}
		result[$i]=$temp

		[[ $debugging == 1 ]] && echo "switch result : #$pick [${result[$pick]}] and $i [${result[$i]}]" >> $debugPath

		local i=$((i + 1))
	done

	echo ${result[@]}
}

play_midi () {
	local song="`echo $1 | fromHtmlEnc`"
	local cmd="$timidity \"$song\" > /dev/null 2> /dev/null"
	#eval $timidity "$song" > /dev/null 2> /dev/null
	eval "$cmd &"
	soundCmdPID=$!
	wait $soundCmdPID
}

play_digital () {
	local song="`echo $1 | fromHtmlEnc`"
	local cmd="$alsaplayer \"$song\" > /dev/null 2> /dev/null"
	#eval $alsaplayer "$song" > /dev/null 2> /dev/null
	[[ $debugging == 1 ]] && echo "Playing song with command : $cmd" >> $debugPath
	eval "$cmd &"
	soundCmdPID=$!
	wait $soundCmdPID
}

play_mod () {
	local song="`echo $1 | fromHtmlEnc`"
	local cmd="$mikmod \"$song\" > /dev/null 2> /dev/null"
	#eval $mikmod "$song" > /dev/null 2> /dev/null
	eval "$cmd &"
	soundCmdPID=$!
	wait $soundCmdPID
}

play_video () {
	local song="`echo $1 | fromHtmlEnc`"
	if [ $debugging = 0 ]; then
		local cmd="$mplayer \"$song\" > /dev/null 2> /dev/null"
	else
		local cmd="$mplayer \"$song\" >> $debugPath 2>&1"
	fi
	#eval $mplayer "$song" > /dev/null 2> /dev/null
	eval "$cmd &"
	soundCmdPID=$!
	wait $soundCmdPID
}

announce () {
	local song=$1
	local stype=$2

	message "now playing $stype music file : `echo \"$song\" | fromHtmlEnc | basename2 -`" $quiet &
}

# pretty path for compressed directories (harmless for other formats)
prettyPath () {
	echo `echo $1 | sed 's/^@\(.*\)@\(.*\)@\(.*\)$/\1\2\/\3/'`
}

#echo `prettyPath "/home/nik_89/houba.tar.gz/something.mp3"`

#exit 0

play_song () {
	#echo "play_song: count $#"
	local song=$1
	shift 1
	typeset -a list
	list=($@)
	local songPath=$song
	local compressed=0
	local inComp=0 # inside a compressed file

	[[ $debugging == 1 ]] && echo "play_song : $song" >> $debugPath

	# compressed directory support :D
	if [[ "$song" != "1" ]] && [[ "`echo $song | sed -e 's/^@.*/1/'`" == "1" ]]; then
		local inComp=1
		local songPath="`prettyPath \"$song\"`"
		local song="`getComprFile \"$song\"`"
	fi

	# check for compression extention
	case `echo $song | sed 's/[^\.]*\.//g'` in
		gz|bz2|zip)
			local compressed=1
			local song1=`echo $song | sed -e 's/\(.*\)\(\.gz\|\.bz2\|\.zip\)$/\1/'`
		;;

		*) local song1=$song
		;;
	esac

	case `echo $song1 | fromHtmlEnc | sed 's/[^\.]*\.//g' | sed 's/\(.*\)/\L\1\E/'` in
		mp3|ogg|wav|flac)
			if [[ $compressed -eq 1 ]]; then
				message "compressed file format not supported" $quiet
			else
				announce "$songPath" "digital"
				play_digital "$song"
			fi
		;;

		flv|wma|mp4|webm|mkv)
			if [[ $compressed -eq 1 ]]; then
				message "compressed file format not supported" $quiet
			else
				announce "$songPath" "video"
				play_video "$song"
			fi
		;;

		mid|midi)
			if [[ $compressed -eq 1 ]]; then
				message "compressed file format not supported" $quiet
			else
				announce "$songPath" "midi"
				play_midi "$song"
			fi
		;;

		mod|xm|s3m|it|mtm|uni)
			# supports compressed files transparently
			announce "$songPath" "amiga"
			play_mod "$song"
		;;

		*)
			message "unhandled music format : `basename $songPath | fromHtmlEnc`" $quiet
		;;
	esac

	# the temporary file is deleted
	if [[ $inComp == 1 ]]; then
		if [[ -d "`echo $song | fromHtmlEnc`" ]]; then
			rm -Rf "`echo $song | fromHtmlEnc`"
		else
			rm -f "`echo $song | fromHtmlEnc`"
		fi
	fi

	[[ ! ${#list[@]} == 0 ]] && play_song ${list[@]}
}

playPlaylist () {
	if [[ "`echo $@ | sed 's/^ *$//'`" == "" ]]; then
		message "Playlist is empty, maybe you forgot to use the recursive (-r or --recursive) argument?" $quiet
		exit 1
	fi
	typeset -a playlist

	if [[ $shuffle == 1 ]]; then
		playlist=(`randomnizePlaylist2 $@`)
	else
		playlist=("$@")
	fi

	#echo "current playlist count : ${#playlist[@]} -- $#"
	play_song ${playlist[@]}

	if [[ $loop == 1 ]]; then
		playPlaylist ${playlist[@]}
	fi
}


message "There are ${#music[@]} songs loaded" $quiet

[[ $debugging == 1 ]] && echo "Loaded the files : \"${music[@]}\"" >> $debugPath


progExit
