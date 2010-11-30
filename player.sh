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

showHelp () {
	printf "player.sh [OPTIONS] ... [FILES]\n"
	printf "	High order music player.\n"
	printf "	plays various music files transparently.\n"
	echo
	printf "	-h,--help	This help\n"
	printf "	-s,--shuffle	shuffle the playlist\n"
	printf "	-l,--loop	loops the playlist\n"
	printf "	-r,--recursive	recursively handle directories\n"
	printf "	-y,--speak	use eSpeak to transmit messages\n"
	echo
}

# loop files in a compressed file
loopFilesComp () {
	recursive=$1

	shift 1

	files=""
	path=""
	comprF=""
	case `echo $1 | sed 's/.*\(tar.gz\|tar.bz2\|tar.xz\|zip\|rar\)/\1/'` in
		tar.gz) #echo a bzip compressed file
			files=`gzip -cd $1 | tar -t | sed 's/ /%20/g'`
			path=`dirname $1`
			comprF=`basename $1`
		;;

		tar.bz2) #echo a bzip2 compressed file
			files=`bzip2 -cdk $1 | tar -t | sed 's/ /%20/g'`
			path=`dirname $1`
			comprF=`basename $1`
		;;

		tar.xz) #echo a xz compressed file
			files=`xz -cdk $1 | tar -t | sed 's/ /%20/g'`
			path=`dirname $1`
			comprF=`basename $1`
		;;

		zip) #echo a zip compressed file
			files=`unzip -qq -l $1 | sed -e 's/^ *[^ ]* *[^ ]* *[^ ]* *//' -e 's/ /%20/g'`
			path=`dirname $1`
			comprF=`basename $1`
		;;

		rar) #echo a rar compressed file
			files=`unrar lb $1 | sed 's/ /%20/g'`
			path=`dirname $1`
			comprF=`basename $1`
		;;

		*) #echo not a compressed directory file
			exit 0
		;;
	esac

	# first step : filter only directories
	#echo $files | sed '/.*\/$/ \! d'
	parent_dir=""
	for i in $files; do
		parent_dir="$parent_dir `echo $i | sed '/.*\/$/! d'`"
		break
	done

	# delete all directories (the content of the dirs are kept though)
	tmp=""
	for i in $files; do
		#parent_dir="$parent_dir `echo $i | sed '/.*\/$/! d'`"
		tmp="$tmp `echo $i | sed '/.*\/$/ d'`"
	done
	files="$tmp"

	if [ "$parent_dir" == " " ] || [ "$parent_dir" == "" ]; then
		parent_dir="./"
	fi

	#echo $parent_dir

	# second step : filter all the files and directories not in the parent
	#		directory if recursion is not activated.
	files2=""
	for i in $files; do
		curparrent=`dirname $i`
		#echo $curparrent -- \"$parent_dir\"
		if [ "$recursive" == "1" ] || [ "${curparrent}/" == $parent_dir ]; then
			#echo "-->" $i
			files2="$files2 @$path/@$comprF@$i"
		fi
	done

	echo $files2
}


tempDir="/tmp/player.sh"

getComprFile () {
	if [ ! -e $tempDir ]; then
		mkdir $tempDir
	fi

	#echo $1
	declare -a comp=(`echo $1 | sed 's/^@// ; s/@/ /g'`)

	if [ "${comp[2]}" != "1" ] && [ "`echo ${comp[2]} | sed 's/.*\/$/1/'`" == "1" ]; then
		# this is a directory, we don't handle that
		exit 0
	fi

	opwd=$PWD

	cd $tempDir

	tmp="`echo ${comp[2]} | sed 's/%20/ /g'`"

	case `echo ${comp[1]} | sed 's/.*\(tar.gz\|tar.bz2\|tar.xz\|zip\|rar\)/\1/'` in
		tar.gz) #echo a bzip compressed file
			tar -zxf $opwd/${comp[0]}${comp[1]} "$tmp"
		;;

		tar.bz2) #echo a bzip2 compressed file
			tar -jxf $opwd/${comp[0]}${comp[1]} "$tmp"
		;;

		tar.xz) #echo a xz compressed file
			xz -cdk $opwd/${comp[0]}${comp[1]} | tar /dev/stdin "$tmp"
		;;

		zip) #echo a zip compressed file
			unzip -qq $opwd/${comp[0]}${comp[1]} "$tmp"
		;;

		rar) #echo a rar compressed file
			tmp2="`echo $tmp | sed 's/^\.\///'`"
			unrar x $opwd/${comp[0]}${comp[1]} "$tmp2" > /dev/null 2> /dev/null
		;;

		*) #echo not a compressed directory file
			exit 0
		;;
	esac

	cd $opwd

	echo ${tempDir}/${comp[2]}
}

#houba=`loopFilesComp 0 $1`
#echo $houba

#for i in $houba; do
#	nFile=`getComprFile "$i"`
#	if [ -e "$nFile" ]; then
#		echo $nFile
#		rm -f $nFile
#	fi
#done

#exit 0

loopFiles () {
	_result=""
	recursive=$1

	shift 1

	while [ 1 -eq 1 ]; do
		if [ "$1" == "" ]; then
			break
		fi

		#echo $1

		# fixes files containing spaces until they
		# are later converted to %20
		processed=`echo "$1" | sed 's/\([^\\]\) /\1\\ /g'`

		if [ "$recursive" == "1" ]; then
			_result="$_result `preparePath \"$processed\" 1`"
		else
			_result="$_result `preparePath \"$processed\" 2`"
		fi

		shift 1
	done

	echo $_result
}

preparePath () {
	case `echo $1 | sed 's/.*\(tar.gz\|tar.bz2\|tar.xz\|zip\|rar\)/\1/'` in

		tar.gz|tar.bz2|tar.xz|zip|rar)
			result=`loopFilesComp "$2" "$1"`
		;;

		*)
			if [ -f "$1" ] && [ -r "$1" ] ; then
				# we change any in file spaces to %20 
				# to prepare the file entries to be used
				result=`echo $1 | sed 's/ /%20/g'`
			elif [ -d "$1" ] && [ "$2" != "2" ]; then
				result=`loopFiles "$2" "${1}"/*`
			else result="`echo $1 | sed 's/ /%20/g'`"
			fi
		;;
	esac

	echo $result
}

#preparePath "$1"

#houba=`preparePath $1`

#echo Houba : $houba

#exit 0

music=""
shuffle=0
loop=0
recurse=0
espeak=0
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

		*)
#			if [ -f $1 ] && [ -r $1 ] ; then
#				# we change any in file spaces to %20 
#				# to prepare the file entries to be used
#				music="${music} `echo $1 | sed 's/ /%20/g'`"
#			elif [ -d $1 ]; then
#				ls ${1}/*.*
#				echo $1
#			fi
			if [ $recurse == 1 ]; then
				music="${music} `preparePath \"$1\" 1`"
			else
				music="${music} `preparePath \"$1\"`"
			fi
		;;
	esac

	shift 1
#	break
done

if [ "$music" == "" ]; then
	showHelp
	exit 0
fi

#echo $music

#exit 0

progExit () {
	echo "Exiting player.sh"
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
			pick=$(((pick + 1) % $len))
		done

		i=$((i + 1))
	done

	echo ${result[@]}
}

play_midi () {
	song=`echo $1 | sed -e 's/%20/\\ /g'`
	#timidity "$song" > /dev/null 2> /dev/null
	$timidity "$song" > /dev/null 2> /dev/null
}

play_digital () {
	song=`echo $1 | sed -e 's/%20/\\ /g'`
	#radio -q "$song"
	$alsaplayer "$song" > /dev/null 2> /dev/null
}

play_mod () {
	song=`echo $1 | sed -e 's/%20/\\ /g'`
	#mikmod -p 0 -q "$song"
	$mikmod "$song"
}

play_video () {
	song=`echo $1 | sed -e 's/%20/\\ /g'`
	#mplayer -vo null -quiet "$song" 2> /dev/null > /dev/null
	$mplayer "$song" > /dev/null 2> /dev/null
}

play_song () {
	local song=$1
	shift 1
	local list=$@
	compressed=0
	inComp=0 # inside a compressed file

	# compressed directory support :D
	if [ "$song" != "1" ] && [ "`echo $song | sed 's/^@.*/1/'`" == "1" ]; then
		inComp=1
		song=`getComprFile "$song"`
	fi

	# check for compression extention
	case `echo $song | sed 's/[^\.]*\.//g'` in
		gz|bz2|zip)
			compressed=1
			song1=`echo $song | sed 's/\(.*\)\(\.gz\|\.bz2\|\.zip\)$/\1/'`
		;;

		#xz)
		#;;

		*)
			song1=$song
		;;
	esac

	case `echo $song1 | sed 's/[^\.]*\.//g' | sed 's/\(.*\)/\L\1\E/'` in
		mp3|ogg|wav)
			if [ $compressed -eq 1 ]; then
				echo compressed file format not supported
				if [ $espeak == 1 ]; then
					$speak "compressed file format not supported" &
				fi
			else
				echo now playing digital music file : $song
				if [ $espeak == 1 ]; then
					$speak "now playing digital music file : `basename $song | sed 's/%20/ /g'`" &
				fi
				play_digital "$song"
			fi
		;;

		flv|wma)
			if [ $compressed -eq 1 ]; then
				echo compressed file format not supported
				if [ $espeak == 1 ]; then
					$speak "compressed file format not supported" &
				fi
			else
				echo now playing video music file : $song
				if [ $espeak == 1 ]; then
					$speak "now playing video music file : `basename $song | sed 's/%20/ /g'`" &
				fi
				play_video "$song"
			fi
		;;

		mid|midi)
			if [ $compressed -eq 1 ]; then
				echo compressed file format not supported
				if [ $espeak == 1 ]; then
					$speak "compressed file format not supported" &
				fi
			else
				echo now playing midi music file : $song
				if [ $espeak == 1 ]; then
					$speak "now playing midi music file : `basename $song | sed 's/%20/ /g'`" &
				fi

				play_midi "$song"
			fi
		;;

		mod|xm|s3m|it|mtm)
			# supports compressed files transparently
			echo now playing amiga music file : $song
			if [ $espeak == 1 ]; then
				$speak "now playing amiga music file : `basename $song | sed 's/%20/ /g'`" &
			fi
			play_mod "$song"
		;;

		*)
			echo unhandled music format : $song
			if [ $espeak == 1 ]; then
				$speak "unhandled music format : `basename $song | sed 's/%20/ /g'`"
			fi
		;;
	esac

	if [ $inComp == 1 ]; then
		rm -f "`echo $song | sed 's/%20/ /g'`"
	fi

	[ ! "$list" == "" ] && play_song $list
}

playPlaylist () {
	if [ $shuffle == 1 ]; then
		declare -a playlist=(`randomnizePlaylist "$@"`)
	else
		declare -a playlist=("$@")
	fi

	#echo ${playlist[@]}

	play_song "${playlist[@]}"

	if [ $loop = 1 ]; then
		playPlaylist "${playlist[@]}"
	fi
}

playPlaylist "$music"

progExit
