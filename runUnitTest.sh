#! /bin/sh

source ./player.sh
source ./unitTest.sh

# test tuple
echo "#1 - Tuple tests"

echo "easy tuple"
rawData1="1"
rawData2="2"
tuple="`mkTuple \"$rawData1\" \"$rawData2\"`"
unitTestFunction "a real tuple" "isTuple \"$tuple\"" "1"
unitTestFunction "1st content" "fst \"$tuple\"" "$rawData1"
unitTestFunction "2nd content" "snd \"$tuple\"" "$rawData2"

echo "non tuple"
nonTuple="1 2"
unitTestFunction "valid tuple" "isTuple \"$nonTuple\"" "0"

echo "very tricky tuple"
rawData1="@@@3   3   4    1 2  oeuou7       3   4    872uaoeu,87,6,576,765,"
rawData2="@ZALBAR,@@@BAR,@"
trickyTuple="`mkTuple \"$rawData1\" \"$rawData2\"`"
unitTestFunction "valid tuple" "isTuple \"$trickyTuple\"" "1"
unitTestFunction "1st content" "fst \"$trickyTuple\"" "$rawData1"
unitTestFunction "2nd content" "snd \"$trickyTuple\"" "$rawData2"

echo "real tuple with simple spaced content"
rawData1="1 2"
rawData2="3 4 5 6"
spacedTuple="`mkTuple \"$rawData1\" \"$rawData2\"`"
unitTestFunction "valid tuple" "isTuple \"$spacedTuple\"" "1"
unitTestFunction "1st content" "fst \"$spacedTuple\"" "$rawData1"
unitTestFunction "2nd content" "snd \"$spacedTuple\"" "$rawData2"

echo "specific hard tuple test"
rawData1='01 - Grabbag (Theme from Duke Nukem 3D) [Lee Jackson].mid'
rawData2='01 - Grabbag (Theme from Duke Nukem 3D).mid'
rawData3='test%2f test%2f1 test%2f2 test%2f3'

resultTuple1="`mkTuple \"$rawData1\" \"$rawData2\"`"
resultTuple2="`mkTuple \"\`echo \"$rawData1\" | toHtmlEnc\`\" \"\`echo \"$rawData2\" | toHtmlEnc\`\" `"
resultTuple3="`mkTuple \"\" \"$rawData1 $rawData2 $rawData3\"`"

echo "without encoding"
unitTestFunction "valid tuple" "isTuple \"$resultTuple1\"" "1"
unitTestFunction "1st content" "fst \"$resultTuple1\"" "$rawData1"
unitTestFunction "2nd content" "snd \"$resultTuple1\"" "$rawData2"
echo "with encoding"
unitTestFunction "valid tuple" "isTuple \"$resultTuple2\"" "1"
unitTestFunction "1st content" "fst \"$resultTuple2\" | fromHtmlEnc" "$rawData1"
unitTestFunction "2nd content" "snd \"$resultTuple2\" | fromHtmlEnc" "$rawData2"
#unitTestFunction "valid tuple" "isTuple \"$resultTuple1\"" "1"
echo "agglomerate"
unitTestFunction "valid tuple" "isTuple \"$resultTuple3\"" "1"
unitTestFunction "1st content" "fst \"$resultTuple3\"" ""
unitTestFunction "2nd content" "snd \"$resultTuple3\"" "$rawData1 $rawData2 $rawData3"

echo "tuple creation with very spaced content"
content1="foo     bar"
content2="zum     tidum"
resultTuple="`mkTuple \"$content1\" \"$content2\"`"
tupleFst="`fst \"$resultTuple\"`"
tupleSnd="`snd \"$resultTuple\"`"
unitTestFunction "valid tuple" "isTuple \"$resultTuple\"" "1"
unitTestFunction "1st content" "fst \"$resultTuple\"" "$tupleFst"
unitTestFunction "2nd content" "snd \"$resultTuple\"" "$tupleSnd"

echo "#1 - Tuple tests complete"


# test sep
echo "#2 - Tuple 'sep' tests"

echo "simple test 1"
rawData1='test.zsh~'
resultTuple="`sep \",\" \"$rawData1\"`"
unitTestFunction "valid tuple" "isTuple \"$resultTuple\"" "1"
unitTestFunction "1st content" "fst \"$resultTuple\"" "$rawData1"
unitTestFunction "2nd content" "snd \"$resultTuple\"" ""

echo "simple test 2"
rawData1=''
resultTuple="`sep \",\" \"$rawData1\"`"
unitTestFunction "valid tuple" "isTuple \"$resultTuple\"" "1"
unitTestFunction "1st content" "fst \"$resultTuple\"" "," # this is special, because of the way 'sep' works, it actually takes the first argument as the actual data (since the second is empty), this is why we expect this result
unitTestFunction "2nd content" "snd \"$resultTuple\"" ""

echo "simple test 3"
rawData1="\'zum dum.txt\'"
rawData2="\'ahah.fob\'"
resultTuple="`sep \",\" \"$rawData1,$rawData2\"`"
unitTestFunction "valid tuple" "isTuple \"$resultTuple\"" "1"
unitTestFunction "1st content" "fst \"$resultTuple\"" "$rawData1"
unitTestFunction "2nd content" "snd \"$resultTuple\"" "$rawData2"

echo "complex test 1"
rawData1='Diablo 2 LOD'
rawData2=' B2 C, D3 E, FF444 Z B e'
resultTuple="`sep \",\" \"$rawData1,$rawData2\"`"
unitTestFunction "valid tuple" "isTuple \"$resultTuple\"" "1"
unitTestFunction "1st content" "fst \"$resultTuple\"" "$rawData1"
unitTestFunction "2nd content" "snd \"$resultTuple\"" "$rawData2"

echo "complex test 2"
rawData1='Diablo 2 LOD'
rawData2=' Diablo15YA.part1.rar, Diablo2_LOD.rar, test.zsh, test.zsh~'
resultTuple="`sep \",\" \"$rawData1,$rawData2\"`"
unitTestFunction "valid tuple" "isTuple \"$resultTuple\"" "1"
unitTestFunction "1st content" "fst \"$resultTuple\"" "$rawData1"
unitTestFunction "2nd content" "snd \"$resultTuple\"" "$rawData2"

echo "#2 - Tuple 'sep' tests complete"

echo "#3 - File load tests"

echo "simplest directory"
[[ -d ./test ]] && rm -Rf ./test/
mkdir test
touch test/1
touch test/2
touch test/3

rawData1="test/1"
rawData2="test/2"
rawData3="test/3"
encData1="`printf \"%s\" \"$rawData1\" | toHtmlEnc`"
encData2="`printf \"%s\" \"$rawData2\" | toHtmlEnc`"
encData3="`printf \"%s\" \"$rawData3\" | toHtmlEnc`"
expectedResult="$encData1 $encData2 $encData3"
unitTestFunction "valid content" "preparePath test 1" "$expectedResult"

[[ -d ./test ]] && rm -Rf ./test/

echo "simple directory with spaced file names"
[[ -d ./test ]] && rm -Rf ./test/
mkdir test
touch test/1
touch test/foo\ \ \ \ \ \ \ \ bar
touch test/zum\ \ \ \ \ ti\ \ dum

rawData1="test/1"
rawData2="test/foo        bar"
rawData3="test/zum     ti  dum"
encData1="`printf \"%s\" \"$rawData1\" | toHtmlEnc`"
encData2="`printf \"%s\" \"$rawData2\" | toHtmlEnc`"
encData3="`printf \"%s\" \"$rawData3\" | toHtmlEnc`"
expectedResult="$encData1 $encData3 $encData2"
unitTestFunction "valid content" "preparePath test 1" "$expectedResult"

[[ -d ./test ]] && rm -Rf ./test/

echo "#3 - File load tests complete"

echo "#4 - Compressed file load tests"
function toEncFormat() {
	cPath="$1"
	encFile="$2"
	encContent="`cat -`"

	eCPath="`printf \"$cPath\" | toHtmlEnc`"
	eEncFile="`printf \"$encFile\" | toHtmlEnc`"
	#encContent="`printf \"$encContent\" | toHtmlEnc`"

	echo "@$eCPath/@$eEncFile@$encContent"
}

echo "simplest directory"
[[ -d ./test ]] && rm -Rf ./test/
mkdir test
touch test/1
touch test/2
touch test/3

rawData1="test/1"
rawData2="test/2"
rawData3="test/3"
encData1="`printf \"%s\" \"$rawData1\" | toHtmlEnc`"
encData2="`printf \"%s\" \"$rawData2\" | toHtmlEnc`"
encData3="`printf \"%s\" \"$rawData3\" | toHtmlEnc`"
echo "xz"
encDirPath='.'
encDirName='test.tar.xz'
encDirFullPath="$encDirPath/$encDirName"
[[ -e $encDirFullPath ]] && rm $encDirFullPath
tar -Jcf $encDirFullPath test/
innerEncData1="`printf \"%s\" \"$encData1\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
innerEncData2="`printf \"%s\" \"$encData2\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
innerEncData3="`printf \"%s\" \"$encData3\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
expectedResult="$innerEncData1 $innerEncData2 $innerEncData3"
unitTestFunction "valid content" "preparePath $encDirFullPath 1" "$expectedResult"
[[ -e $encDirFullPath ]] && rm $encDirFullPath

[[ -d ./test ]] && rm -Rf ./test/

echo "simple directory with spaced file names"
[[ -d ./test ]] && rm -Rf ./test/
mkdir test
touch test/1
touch test/foo\ \ \ \ \ \ \ \ bar
touch test/zum\ \ \ \ \ ti\ \ dum

rawData1="test/1"
rawData2="test/foo        bar"
rawData3="test/zum     ti  dum"
encData1="`printf \"%s\" \"$rawData1\" | toHtmlEnc`"
encData2="`printf \"%s\" \"$rawData2\" | toHtmlEnc`"
encData3="`printf \"%s\" \"$rawData3\" | toHtmlEnc`"

echo "gzip"
encDirPath='.'
encDirName='test.tar.gz'
encDirFullPath="$encDirPath/$encDirName"
[[ -e $encDirFullPath ]] && rm $encDirFullPath
tar -zcf $encDirFullPath test/
innerEncData1="`printf \"%s\" \"$encData1\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
innerEncData2="`printf \"%s\" \"$encData2\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
innerEncData3="`printf \"%s\" \"$encData3\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
expectedResult="$innerEncData1 $innerEncData3 $innerEncData2"
unitTestFunction "valid content" "preparePath $encDirFullPath 1" "$expectedResult"
[[ -e $encDirFullPath ]] && rm $encDirFullPath

echo "bz2"
encDirPath='.'
encDirName='test.tar.bz2'
encDirFullPath="$encDirPath/$encDirName"
[[ -e $encDirFullPath ]] && rm $encDirFullPath
tar -jcf $encDirFullPath test/
innerEncData1="`printf \"%s\" \"$encData1\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
innerEncData2="`printf \"%s\" \"$encData2\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
innerEncData3="`printf \"%s\" \"$encData3\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
expectedResult="$innerEncData1 $innerEncData3 $innerEncData2"
unitTestFunction "valid content" "preparePath $encDirFullPath 1" "$expectedResult"
[[ -e $encDirFullPath ]] && rm $encDirFullPath

echo "xz"
encDirPath='.'
encDirName='test.tar.xz'
encDirFullPath="$encDirPath/$encDirName"
[[ -e $encDirFullPath ]] && rm $encDirFullPath
tar -Jcf $encDirFullPath test/
innerEncData1="`printf \"%s\" \"$encData1\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
innerEncData2="`printf \"%s\" \"$encData2\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
innerEncData3="`printf \"%s\" \"$encData3\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
expectedResult="$innerEncData1 $innerEncData3 $innerEncData2"
unitTestFunction "valid content" "preparePath $encDirFullPath 1" "$expectedResult"
[[ -e $encDirFullPath ]] && rm $encDirFullPath

echo "zip"
encDirPath='.'
encDirName='test.zip'
encDirFullPath="$encDirPath/$encDirName"
[[ -e $encDirFullPath ]] && rm $encDirFullPath
zip -r $encDirFullPath test/ > /dev/null 2>&1
innerEncData1="`printf \"%s\" \"$encData1\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
innerEncData2="`printf \"%s\" \"$encData2\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
innerEncData3="`printf \"%s\" \"$encData3\" | toEncFormat \"$encDirPath\" \"$encDirName\"`"
expectedResult="$innerEncData1 $innerEncData3 $innerEncData2"
unitTestFunction "valid content" "preparePath $encDirFullPath 1" "$expectedResult"
[[ -e $encDirFullPath ]] && rm $encDirFullPath

[[ -d ./test ]] && rm -Rf ./test/

echo "#4 - Compressed file load tests complete"


