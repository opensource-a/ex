# -------------------------------------------------------------
# Get the AWS Region
aws_region=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'` >/dev/null 2>&1
# echo $aws_region
#--------------------------------------------------------------
# Send verification emails to all participants in exercise_participants.csv (column 3)
email_lines=$(cat ../exercise_participants.csv | wc -l)
((email_lines=email_lines+1))
row_no=2
#echo $row_no
while [ $row_no -lt $email_lines ]
do
	#echo $row_no
	cell_value=$(../common/csv_read.sh ../exercise_participants.csv "4,$row_no")
	aws ses verify-email-identity --email-address $cell_value --region $aws_region
	#echo $cell_value $aws_region
	((row_no=row_no+1))
done
