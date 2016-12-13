#! /bin/sh

# generic script meant to implement unit tests
# this is to test if functions are working according to specifications.


# first argument is a text describing this test.
# Second argument is a string with the function to test and its arguments.
# This is to simulate the way a lazy language would implement this.
# The third argument is the result that we expect from this function.
#
# This function will exit with an error for the whole script in case it detects
# a test which does not pass.
function unitTestFunction() {
	local testDescription=$1
	local stringifiedFunction=$2
	local expectedResult=$3

	printf "Running test : $testDescription - result : "

	local result="`eval \"$stringifiedFunction\"`"

	if [ "$result" != "$expectedResult" ]; then
		echo "failed"
		echo "Test : $testDescription - '$stringifiedFunction\` resulted in '$result\` rather than the expected result '$expectedResult\`"
		echo "Bailing out"
		exit 1
	else
		echo "passed"
	fi
}

#unitTestFunction "simple test 1" "echo 1" "1"
#unitTestFunction "simple test 2" "echo $((5 + 2 + 11))" "18"
#unitTestFunction "failing test" "echo 2" "3"
