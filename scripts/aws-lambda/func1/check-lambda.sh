lambda_function_name=lambda-echo
echo "Check style 1"
result=$( aws lambda get-function --function-name $lambda_function_name --query Configuration.[FunctionName])
echo $result
if [ $? == 0 ]; then
   echo "Lambda Function:[${result}], already exists, skipping.."
fi

echo "Check style 2"
result=$( aws lambda list-functions --output text --query [])
## Result if blank
##
##{
##    "Functions": []
##}
##
echo $result
if [ "$result" == "None" ]; then
   echo "Lambda Function:[${result}], no Lambda functions exist!"
fi

