 aws lambda invoke \
--invocation-type RequestResponse \
--function-name alexa-firebrand-facts \
--log-type Tail \
--payload file://payload.json \
payload-test-result.txt

cat payload-test-result.txt && echo