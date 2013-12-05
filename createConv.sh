#! /bin/bash

range () {
	local f=$1
	local start=$2
	local end=$3

	local result=""
	while [ $((start <= end)) == 1 ] ; do
		local result="$result `$f $start`"
		local start=$((start + 1))
	done

	echo $result
}

toHex () {
	printf "%x" $1
}

# turns an hex number into a specific regex rule
toSpecial () {
	num=`toHex $1`
	char=`printf "\x$num"`
	case "$char" in
		\%) # 0x25 37
			echo ""
		;;

		@|-|=)
			echo ""
		;;

		\$)
			echo "s/\\\\\$/%$num/g;"
		;;

		\,|\!|\*|\"|\.|\/|\^|\`|[|])
			echo "s/\\$char/%$num/g;"
		;;

		\\)
			echo "s/\\\\\\\\/%$num/g;"
		;;

		*)
			echo "s/$char/%$num/g;"
		;;
	esac
}

# turns an hex number into a specific regex rule
fromSpecial () {
	num=`toHex $1`
	char=`printf "\x$num"`
	case "$char" in
		\%) # 0x25 37
			echo ""
		;;

		@|-|=)
			echo ""
		;;

		\$)
			echo "s/%$num/\\\\\$/g;"
		;;

		\,|\!|\*|\"|\.|\/|\^|\`|[|])
			echo "s/%$num/\\$char/g;"
		;;

		\\)
			echo "s/%$num/\\\\\\\\/g;"
		;;

		*)
			echo "s/%$num/$char/g;"
		;;
	esac
}

# convert special characters to html style encoding
toHtmlEnc () {
	# 32 to 47
	# 58 to 64
	# 91 to 96
	# 123 to 127
	local rng1=`range toSpecial 32 47`
	local rng2=`range toSpecial 58 64`
	local rng3=`range toSpecial 91 96`
	local rng4=`range toSpecial 123 127`
	echo sed -e \"$rng1\" -e \"$rng2\" -e \"$rng3\" -e \"$rng4\"
}

fromHtmlEnc () {
	# 32 to 47
	# 58 to 64
	# 91 to 96
	# 123 to 127
	local rng1=`range fromSpecial 32 47`
	local rng2=`range fromSpecial 58 64`
	local rng3=`range fromSpecial 91 96`
	local rng4=`range fromSpecial 123 127`
	echo sed -e \"$rng1\" -e \"$rng2\" -e \"$rng3\" -e \"$rng4\"
}

#range toSpecial 123 127
#toSpecial 20

echo "#! /bin/bash"
echo
echo "# the two following functions are generated from createConv.sh"
echo "toHtmlEnc () {"
#printf "\techo \$1 | "
echo "`toHtmlEnc`"
echo "}"
echo
echo "# see the message before toHtmlEnc"
echo "fromHtmlEnc () {"
#printf "\techo \$1 | "
echo "`fromHtmlEnc`"
echo "}"
echo
echo "result=\`echo \"\$1\" | toHtmlEnc\`"
echo "echo encoded \$result"
echo "echo \$result | fromHtmlEnc"
