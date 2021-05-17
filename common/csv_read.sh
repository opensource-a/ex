#!/bin/bash
cell=$2
row_number=1
while IFS=',' read -r csv_row; do
	column_number=1
	for cell_value in $(echo $csv_row | sed "s/,/ /g")
	do
    		if [ "$column_number,$row_number" == $cell ]; then
			echo "$cell_value"
		fi
		((column_number=column_number+1))
	done
	((row_number=row_number+1))
done < $1
IFS=$' \t\n'
