#!/bin/bash
# Get the 12 digit AWS account ID
aws_account=$(aws sts get-caller-identity --query Account --output text) >/dev/null 2>&1
# echo $aws_account
# -------------------------------------------------------------
# Get the AWS Region
aws_region=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'`
# echo $aws_region
# -------------------------------------------------------------
# Get the AWS Region
while IFS="," read -r rec_column1 rec_column2 rec_column3 rec_column4 rec_column5 rec_column6 rec_column7 rec_column8 rec_column9 rec_column10 rec_column11 rec_column12 rec_column13 rec_column14
do
  	#echo "aws cloudformation delete-stack --stack-name $rec_column13 --region $aws_region"
	aws s3api delete-objects --bucket $rec_column13 --delete "$(aws s3api list-object-versions --bucket $rec_column13 --output=json --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"  >/dev/null 2>&1
	aws cloudformation delete-stack --stack-name $rec_column13 --region $aws_region >/dev/null 2>&1
done < <(tail -n +2 active_stacks.csv)



echo "Cloud Formation Stacks are being deleted... this may take a few minutes..."



while IFS="," read -r rec_column1 rec_column2 rec_column3 rec_column4 rec_column5 rec_column6 rec_column7 rec_column8 rec_column9 rec_column10 rec_column11 rec_column12 rec_column13 rec_column14
do
        #echo "aws cloudformation wait stack-delete-complete --stack-name $rec_column13 --region $aws_region"
	aws cloudformation wait stack-delete-complete --stack-name $rec_column13 --region $aws_region
done < <(tail -n +2 active_stacks.csv);



rm active_stacks.csv
echo "Participant_ID,Participant_First_Name,Participant_Last_Name,Participant_Email,Participant_Password,EC2_Stack_Creation_Time,EC2_Stack_Name,EC2_Instance_IP,EC2_Pem_File,EC2_Instance_ID,Role_of_EC2,S3_Stack_Creation_Time,S3_Stack_Name,S3_Bucket_Arn" > active_stacks.csv

