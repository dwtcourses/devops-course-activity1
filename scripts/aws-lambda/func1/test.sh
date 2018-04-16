outfile=test.txt
#In this example, we do not specify an outfile, lets see what happens
aws lambda invoke \
    --function-name lambda-echo \
	$outfile
echo
echo "Output of the lambda function is:"
cat $outfile
echo
