# How many s3 buckets do you want to launch?
active_stacks_ec2_file="../ec2/active_stacks.csv"
# -------------------------------------------------------------
# Create a timestamp
time_stamp=`date +%Y%m%d%H%M%S`
date_time=`date +%Y-%m-%dT%H:%M:%S`"+00:00"
# -------------------------------------------------------------
# Get the 12 digit AWS account ID
aws_account=$(aws sts get-caller-identity --query Account --output text) >/dev/null 2>&1
#echo $aws_account
# -------------------------------------------------------------
# Get the AWS Region
aws_region=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'` >/dev/null 2>&1
#echo $aws_region
# Get the secret key for Server Side Encryption of secret_document_5.txt
# -------------------------------------------------------------
secret_key=$(cat secret_document_0.key)
# -------------------------------------------------------------
# Setup a S3 bucket to store the cloudformation template
aws s3 mb s3://$aws_account-exercise-s3-$time_stamp >/dev/null 2>&1
#echo "bucket to store cloudformation template created successfully"
# --------------------------------------------------------------
# Copy the Cloud Formation Template to an S3 bucket, so we can reference it from the create-stack CLI command
cp cloudformation-template-for-s3.yaml cloudformation-$aws_account-exercise-s3-$time_stamp.yaml >/dev/null 2>&1
aws s3 cp cloudformation-$aws_account-exercise-s3-$time_stamp.yaml s3://$aws_account-exercise-s3-$time_stamp/ >/dev/null 2>&1
#echo "cloudformation template copied to s3 bucket successfully" >/dev/null 2>&1
while IFS="," read -r rec_column1 rec_column2 rec_column3 rec_column4 rec_column5 rec_column6 rec_column7 rec_column8 rec_column9 rec_column10 rec_column11
do
	# -------------------------------------------------------------
	# Create the Cloud Formation Stack
	stack_name="s3-$rec_column1-$aws_account-exercise-$time_stamp" >/dev/null 2>&1
	#echo $stack_name
	aws cloudformation create-stack --stack-name $stack_name --template-url https://$aws_account-exercise-s3-$time_stamp.s3.amazonaws.com/cloudformation-$aws_account-exercise-s3-$time_stamp.yaml --region $aws_region
done < <(tail -n +2 $active_stacks_ec2_file) >/dev/null 2>&1

echo "Stack creation in progress.... this may take a few minutes to complete..."

s3_count=0

while IFS="," read -r rec_column1 rec_column2 rec_column3 rec_column4 rec_column5 rec_column6 rec_column7 rec_column8 rec_column9 rec_column10 rec_column11
do
	stack_name="s3-$rec_column1-$aws_account-exercise-$time_stamp" >/dev/null 2>&1
        aws cloudformation wait stack-create-complete --stack-name $stack_name --region $aws_region >/dev/null 2>&1
	echo "$rec_column1,$rec_column2,$rec_column3,$rec_column4,$rec_column5,$rec_column6,$rec_column7,$rec_column8,$rec_column9,$rec_column10,$rec_column11,$date_time,$stack_name,arn:aws:s3:::$stack_name" >> active_stacks.csv
	
	cp bucket-policy-template.json bucket-policy-$stack_name.json
        sed -i "s/S3-BUCKET-ARN/arn:aws:s3:::$stack_name/g" bucket-policy-$stack_name.json
        sed -i "s~EXERCISE-ADMIN-ROLE-ARN~arn:aws:iam::$aws_account:role/$(aws sts get-caller-identity --query Arn --output text | cut -d "/" -f2)~g" bucket-policy-$stack_name.json
        sed -i "s~EXERCISE-PARTICIPANT-ROLE-ARN~$rec_column11~g" bucket-policy-$stack_name.json
        aws s3api put-bucket-policy --bucket $stack_name --policy file://bucket-policy-$stack_name.json
        rm bucket-policy-$stack_name.json
        aws s3 cp secret_document_0.key s3://$stack_name >/dev/null 2>&1
        aws s3 cp secret_document_1.pdf s3://$stack_name >/dev/null 2>&1
        aws s3 cp secret_document_2.png s3://$stack_name >/dev/null 2>&1
        aws s3 cp secret_document_3.csv s3://$stack_name >/dev/null 2>&1
        aws s3 cp secret_document_4.jpg s3://$stack_name >/dev/null 2>&1
        aws s3 cp secret_document_5.txt s3://$stack_name --sse-c-key $secret_key --sse-c AES256 >/dev/null 2>&1
	
	s3_count=$((s3_count+1))

done < <(tail -n +2 $active_stacks_ec2_file)


# -------------------------------------------------------------
# Delete the bucket, template in bucket, locally created template
aws s3 rm s3://$aws_account-exercise-s3-$time_stamp --recursive >/dev/null 2>&1
aws s3 rb s3://$aws_account-exercise-s3-$time_stamp >/dev/null 2>&1
rm cloudformation-$aws_account-exercise-s3-$time_stamp.yaml >/dev/null 2>&1
echo "Successfully launched $s3_count S3 Buckets and copied six secret objects into each."

