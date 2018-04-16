lambda_function_name=lambda-echo
role_name="$lambda_function_name-role"
#aws iam get-role --role-name lambda-echo-role --output text
result=$(aws iam get-role --role-name lambda-echo-role --output text | grep -i ${role_name})
echo $result
if [ $? == 0 ]; then
   echo "[${role_name}], already exists, skipping.."
fi

echo "getting the arn"
arn=$( aws iam get-role --role-name lambda-echo-role --output text --query Role.[Arn])
echo "arn=[$arn]"

