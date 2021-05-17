# How many EC2 Instances do you want to launch?
exercise_participants_file="../exercise_participants.csv"
# -------------------------------------------------------------
# Create a timestamp
time_stamp=`date +%Y%m%d%H%M%S`
date_time=`date +%Y-%m-%dT%H:%M:%S`"+00:00"
# -------------------------------------------------------------
# Get the 12 digit AWS account ID
aws_account=$(aws sts get-caller-identity --query Account --output text) >/dev/null 2>&1
# echo $aws_account
# -------------------------------------------------------------
# Get the AWS Region
aws_region=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'` >/dev/null 2>&1
# echo $aws_region
# -------------------------------------------------------------
# Get the instance ID of this EC2
ec2_instance_id=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep instanceId|awk -F\" '{print $4}'` >/dev/null 2>&1
# echo $ec2_instance_id
# -------------------------------------------------------------
# Get the VPC of this EC2
aws_vpc_id=$(aws ec2 describe-instances --instance-ids $ec2_instance_id --region $aws_region --query Reservations[].Instances[].VpcId --output text) >/dev/null 2>&1
# echo $aws_vpc_id
# -------------------------------------------------------------
# Get the amazon machine image (AMI) ID of the EC2
ec2_image_id=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep imageId|awk -F\" '{print $4}'` >/dev/null 2>&1
#echo $ec2_image_id
# -------------------------------------------------------------
# Get the instance type of the EC2
ec2_instance_type=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep instanceType|awk -F\" '{print $4}'` >/dev/null 2>&1
#echo $ec2_instance_type
# -------------------------------------------------------------
# Get the security groups of the EC2
security_group_ids=$(aws ec2 describe-instances --instance-ids $ec2_instance_id --region $aws_region --query Reservations[].Instances[].SecurityGroups[].GroupId[] --output text)
# echo $security_group_ids
# -------------------------------------------------------------
# Setup a S3 bucket to store the cloudformation template
aws s3 mb s3://$aws_account-exercise-ec2-$time_stamp >/dev/null 2>&1
#echo "bucket created successfully"
# -------------------------------------------------------------
# Copy the Cloud Formation Template to an S3 bucket, so we can reference it from the create-stack CLI command
cp cloudformation-template-for-ec2.yaml cloudformation-$aws_account-exercise-ec2-$time_stamp.yaml >/dev/null 2>&1
aws s3 cp cloudformation-$aws_account-exercise-ec2-$time_stamp.yaml s3://$aws_account-exercise-ec2-$time_stamp/ >/dev/null 2>&1
# echo "cloudformation template copied to s3 bucket successfully" >/dev/null 2>&1
# -------------------------------------------------------------
# Get the list of subnets in this VPC
subnet_list=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$aws_vpc_id" --region $aws_region --query Subnets[].SubnetId --output text) >/dev/null 2>&1
# echo $subnet_list
# -------------------------------------------------------------
# Convert the list of subnets in this VPC to an array
arr=($subnet_list) >/dev/null 2>&1
while IFS="," read -r rec_column1 rec_column2 rec_column3 rec_column4 rec_column5
do
        #aws cloudformation delete-stack --stack-name $rec_column2 --region $aws_region
        #echo $rec_column1
	# -------------------------------------------------------------
	# Get a random subnet from this array
	subnet_id=${arr[RANDOM%${#arr[@]} - 1]}
	# echo $subnet_id
	# -------------------------------------------------------------
	# Create the Cloud Formation Stack
	stack_name="ec2-$rec_column1-$aws_account-exercise-$time_stamp" >/dev/null 2>&1
	#echo $stack_name
	aws cloudformation create-stack --stack-name $stack_name --template-url https://$aws_account-exercise-ec2-$time_stamp.s3.amazonaws.com/cloudformation-$aws_account-exercise-ec2-$time_stamp.yaml --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM --region $aws_region --parameters ParameterKey=AmiId,ParameterValue=$ec2_image_id ParameterKey=Vpc,ParameterValue=$aws_vpc_id ParameterKey=Subnet,ParameterValue=$subnet_id  ParameterKey=SecurityGroup,ParameterValue=$security_group_ids
done < <(tail -n +2 $exercise_participants_file)

echo "Stack creation in progress.... this may take a few minutes to complete..."

ec2_count=0

while IFS="," read -r rec_column1 rec_column2 rec_column3 rec_column4 rec_column5
do
	stack_name="ec2-$rec_column1-$aws_account-exercise-$time_stamp" >/dev/null 2>&1
	aws cloudformation wait stack-create-complete --stack-name $stack_name --region $aws_region >/dev/null 2>&1
	stack_ec2_instance_id=$(aws cloudformation describe-stacks --stack-name $stack_name --query 'Stacks[].Outputs[?OutputKey==`EC2InstanceID`].OutputValue[]' --region $aws_region --output text)
	stack_ec2_instance_ip=$(aws cloudformation describe-stacks --stack-name $stack_name  --query 'Stacks[].Outputs[?OutputKey==`EC2PrivateIP`].OutputValue[]' --region $aws_region --output text)
	stack_ec2_role_arn=$(aws cloudformation describe-stacks --stack-name $stack_name --query 'Stacks[].Outputs[?OutputKey==`EC2Role`].OutputValue[]' --region $aws_region --output text)
	echo "$rec_column1,$rec_column2,$rec_column3,$rec_column4,$rec_column5,$date_time,$stack_name,$stack_ec2_instance_ip,$stack_name,$stack_ec2_instance_id,$stack_ec2_role_arn" >> active_stacks.csv
	ec2_count=$((ec2_count+1))
done < <(tail -n +2 $exercise_participants_file)

# -------------------------------------------------------------
# Delete the bucket, template in bucket, locally created template
aws s3 rm s3://$aws_account-exercise-ec2-$time_stamp --recursive >/dev/null 2>&1
aws s3 rb s3://$aws_account-exercise-ec2-$time_stamp >/dev/null 2>&1
rm cloudformation-$aws_account-exercise-ec2-$time_stamp.yaml >/dev/null 2>&1
echo "Successfully launched $ec2_count EC2 Instances"
