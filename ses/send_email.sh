# -------------------------------------------------------------
# Get the AWS Region
aws_region=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'` >/dev/null 2>&1
# echo $aws_region
#--------------------------------------------------------------
# Send exercise instruction emails to all participants in exercise_participants.csv (column2=participant_name, column3=email_address)
email_lines=$(cat ../exercise_participants.csv | wc -l)
((email_lines=email_lines+1))
row_no=2
#echo $row_no
while [ $row_no -lt $email_lines ]
do
        #echo $row_no
	participant_name=$(../common/csv_read.sh ../exercise_participants.csv "2,$row_no")
        email_address=$(../common/csv_read.sh ../exercise_participants.csv "4,$row_no")
	#echo $participant_name
	#echo $email_address
	sed "s/Participant_Email_Address/$email_address/g" email_address_template.json > email_address.json
	sed -e "s/SUBJECT_TEXT/Development Workspace for $participant_name for AWS Exercise./g" -e "s/BODY_HTML/Hello $participant_name, please click on the following link www.google.com to sign in to your workspace/g" email_message_template.json > email_message.json
	#cat email_address.json
	#echo "-----------------------"
	#cat email_message.json
	aws ses send-email --from amadhavan@zeisys.com --destination file://email_address.json --message file://email_message.json --region $aws_region
	rm email_address.json
	rm email_message.json
        # echo $cell_value $aws_region
        ((row_no=row_no+1))
done

