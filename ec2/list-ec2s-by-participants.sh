# What is the file containing the participants and designated ec2s?
exercise_participants_file="active_stacks.csv"


while IFS="," read -r rec_column1 rec_column2 rec_column3 rec_column4 rec_column5 rec_column6 rec_column7 rec_column8 rec_column9 rec_column10 rec_column11
do
	aws s3 cp s3://$rec_column9/$rec_column9.pem ./pem/$rec_column9.pem >/dev/null 2>&1
	chmod 400 ./pem/$rec_column9.pem >/dev/null 2>&1
	echo $rec_column1 - $rec_column2 $rec_column3 - "$(tput setaf 7)ssh -i pem/$rec_column9.pem ec2-user@$rec_column8$(tput sgr 0)"
done < <(tail -n +2 $exercise_participants_file)
