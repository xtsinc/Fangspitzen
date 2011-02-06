#!/bin/bash

printf "%-8s %-9s %-8s %-6s %-6s %s\n" "Date" "Device" "Capacity" "Used" "Free" "Status"

df -H | grep ^/dev/ > /tmp/$$.df
while read line
do
	cur_date=$(date +%D)
	printf "%-8s " $cur_date
	echo $line | awk '{ printf("%-9s %-6s %-6s %-8s",$1,$2,$3,$4,$5); }'
	pusg=$(echo $line | egrep -o "[0-9]+%")
	pusg=${pusg/\%/}

	if [[ $pusg -lt 80 ]]
		then echo SAFE
		else echo ALERT
	fi
done < /tmp/$$.df
