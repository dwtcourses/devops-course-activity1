lambda_function_name=lambda-echo
role_name="$lambda_function_name-role" 
aws iam delete-role --role-name "$role_name"