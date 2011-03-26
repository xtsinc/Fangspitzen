#!/bin/bash

# Last Login
lastlog -u $USER | tail -1 | awk '{print "\n Last Login.. -» "$4, $5, $6, $7" from "$3}'

# SSH Logins
LOGINS=$(uptime | grep -Eo '[0-9]+ users?')
echo -e " SSH Logins.. -» $LOGINS currently logged in."

# Uptime
UPTIME=$(uptime | grep -Eo 'up .+ user' | sed -e 's/:/ hours /' -e 's/ min//' -re 's/^up\s+/Uptime...... -» /' | sed -re 's/,\s+[0-9]+ user$/ minutes/' -e 's/,//g' -e 's/00 minutes//' | sed -re 's/0([1-9] minutes)/\1/' -e 's/(1 hour)s/\1/' -e 's/(1 minute)s/\1/')
echo -e " $UPTIME"

# Load
LOAD=$(uptime | grep -Eo 'average: .+' | sed -e 's/average:/Load........ -»/' -e 's/,//g')
echo -e " $LOAD"

# Home Disk Usage
du -sh $HOME | awk '{print " Disk Usage.. -» Using "$1"B in "$2}'

# Processes
psa=$(($(ps -A h | wc -l)-2))
psu=$(($(ps U $USER h | wc -l)-2))
echo -e " Processes... -» $psu of the $psa running are yours"

# Memory / Swap
memory=$(free -m)
echo -e " Memory...... -» $(echo "$memory" | grep 'Mem: ' | awk '{print "Used: "$3 " MB  Free: "$4 " MB"}')  Swap: $(echo "$memory" | grep 'Swap: ' | awk '{print $3"/"$4 " MB"}')\n"

