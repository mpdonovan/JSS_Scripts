#!/bin/bash

#########################################################################################################
# This script replicates files to the current logged in users home directory from a selected location.  #
#                                                                                                       #
#                                                                                                       #
#                                                                                                       #
#########################################################################################################

# File Name: UserData_Restore.sh
# Created By: Joshua Roskos
# Created On: Thursday, January 9th, 2014
# Modified By: Mike Donovan
# Modified On: Friday, October 13th, 2017

## jamfhelper line break
file=$(find /Library/Application\ Support/JAMF/bin/KISDColorseal.png)
if [ ! -z "$file" ]
then
	useIcon=/Library/Application\ Support/JAMF/bin/KISDColorseal.png
	#echo "found"
else
	useIcon=/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns
	#echo "not found"
fi

JHELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

# Determine Current Logged-In User
USER=`defaults read /Library/Preferences/com.apple.loginwindow lastUserName`

MESSAGE="This will restore files to the currently logged 
in users home folder from the destination of your choice.

If using OneDrive ensure sync client is installed
before continuing."

btnReturned=$("$JHELPER" -windowType utility -title "KISD Mac Systems Admin" -heading "User Restore" -description "$MESSAGE" -button1 "Exit" -defaultButton 1 -button2 "Continue" -icon "$useIcon" -iconSize 64)

if [ "$btnReturned" == "0" ]; then
	exit 0
fi

sourcePath=$(/usr/bin/osascript << EOF
tell application "System Events"
 set getPath to (POSIX path of (choose folder with prompt "Choose Restore location folder"))
end tell
EOF)

# Check for Existing Backup
if [ ! -d "$sourcePath"/UserData/"$USER" ]; then
    MESSAGE="No User data was found for the currently logged in user."

	btnReturned=$("$JHELPER" -windowType utility -title "KISD Mac Systems Admin" -heading "User Restore" -description "$MESSAGE" -button1 "OK" -defaultButton 1 -icon "$useIcon" -iconSize 64)

	if [ "$btnReturned" == "0" ]; then
		exit 0
	fi
else
    # Stamp Log File - Starting rsync
    echo " " >> "$sourcePath/UserData/${USER}Logs/$USER.log"
    echo "=====Starting rSync RESTORE of $USER @ $(date)=====" >> "$sourcePath/UserData/${USER}Logs/$USER.log"
    
    MESSAGE="Restore in progress...... 

This may take several minutes."
    
    /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -windowPosition centre -title "KISD Mac Systems Admin" -alignHeading left -heading "User Restore" -alignDescription left -description "$MESSAGE" -lockHUD -icon "$useIcon" -iconSize 64 &

    # Restore Users Home Directory
    rsync -vzrpog --update --ignore-errors --force --progress --log-file="$sourcePath/UserData/${USER}Logs/$USER.log" "$sourcePath"/UserData/"$USER"/ /Users/"$USER"/

	ps axco pid,command | grep jamfHelper | awk '{ print $1; }' | xargs kill -9
	
    # Stamp Log File - rsync Complete
    echo " " >> "$sourcePath/UserData/${USER}Logs/$USER.log"
    echo "=====Completed rSync RESTORE of $USER @ $(date)=====" >> "$sourcePath/UserData/${USER}Logs/$USER.log"

fi

# Run CHOWN
#chown -R $USER:staff /Users/$USER/

MESSAGE="The Restore is complete"

btnReturned=$("$JHELPER" -windowType utility -title "KISD Mac Systems Admin" -heading "User Restore" -description "$MESSAGE" -button1 "OK" -defaultButton 1 -icon "$useIcon" -iconSize 64)

if [ "$btnReturned" == "0" ]; then
	exit 0
fi
