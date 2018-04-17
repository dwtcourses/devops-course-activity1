OUTFILE=test.txt
FUNCTION_NAME=myfunc1
if [ -z $FUNCTION_NAME ]; then
	echo "ERROR: Required variables have not been set!"
	echo "Please enter a vlue for FUNCTION_NAME, then try again!"
	exit 1
fi
echo "END: Environment variables:"
rm -Rf $OUTFILE
aws lambda invoke \
    --function-name $FUNCTION_NAME \
	$OUTFILE
echo
echo "Output of the lambda function is:"
cat $OUTFILE
echo
