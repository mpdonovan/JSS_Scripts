#!/bin/bash

#########################################################################################################
# This script replicates files from the current logged in users home directory                          #
# to a selected location.                                                                               #
#                                                                                                       #
#                                                                                                       #
# Users can restore their data from Self Service by click on Restore User Data.                         #
#########################################################################################################

# File Name: UserData_Backup.sh
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

MESSAGE="This will backup files from the currently logged
in users home folder to the destination of your choice.

If using OneDrive ensure sync client is installed
before continuing."

btnReturned=$("$JHELPER" -windowType utility -title "KISD Mac Systems Admin" -heading "User Back Up" -description "$MESSAGE" -button1 "Exit" -defaultButton 1 -button2 "Continue" -icon "$useIcon" -iconSize 64)

if [ "$btnReturned" == "0" ]; then
	exit 0
fi

buildExclusionFile()
{
/bin/cat <<EOF > /tmp/UserData_Exclusions.txt
# Home Directory Exclusions
- iTunes
- Microsoft User Data
- Downloads
- .Trash
- Public
- .ssh
- OneDrive*
- Applications
- Library

# User Library Folder Exclusions
- Assistants
- PhotoshopCrashes
- Audio
- Caches
- Calendars
- ColorPickers
- Colors
- Compositions
- Containers
- Cookies
- Favorites
- FileSync
- FontCollections
- Fonts
- GoogleSoftwareUpdate
- iMovie
- Input Methods
- Internet Plug-Ins
- Keyboard Layouts
- Keychains
- LaunchAgents
- LaunchDaemons
- Logs
- Mail
- Parallels
- PDF Services
- PreferencePanes
- Preferences
- Printers
- PubSub
- Saved Application State
- Screen Savers
- Sounds
- Spelling
- SyncedPreferences
- Voices

# User Library Application Support Folder Exclusions
- AddressBook
- Citrix
- Citrix Receiver
- com.apple.QuickLook
- CrashReporter
- Dock
- Microsoft
- Mozilla
- PowerRegister
- Preview
- SyncServices

EOF
}

buildExclusionFile


# Determine Current Logged-In User
USER=`defaults read /Library/Preferences/com.apple.loginwindow lastUserName`

destPath=$(/usr/bin/osascript << EOF
tell application "System Events"
 set getPath to (POSIX path of (choose folder with prompt "Choose Back Up location"))
end tell
EOF)


if [ ! -d "$destPath"/UserData ]; then
	mkdir "$destPath/UserData"
fi

if [ ! -d "$destPath"/UserData/${USER} ]; then
	mkdir "$destPath/UserData/${USER}"
else
	echo "User folder already exists. Exiting Backup utility"
	exit 0
fi

if [ ! -d "$destPath"/UserData/${USER}Logs ]; then
	mkdir "$destPath/UserData/${USER}Logs"

fi

touch "$destPath"/UserData/${USER}Logs/"$USER.log"

echo " " >> "$destPath/UserData/${USER}Logs/$USER.log"
echo "=====Starting rSync BACKUP of $USER @ $(date)=====" >> "$destPath/UserData/${USER}Logs/$USER.log"

MESSAGE="Back Up in progress......

This may take several minutes."

/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -windowPosition centre -title "KISD Mac Systems Admin" -alignHeading left -heading "User Back Up" -alignDescription left -description "$MESSAGE" -lockHUD -icon "$useIcon" -iconSize 64 &

rsync -vzrpog --update --delete --ignore-errors --force --filter='merge /tmp/UserData_Exclusions.txt' --progress --log-file="$destPath/UserData/${USER}Logs/$USER.log" /Users/"$USER"/ "$destPath"/UserData/"$USER"/

ps axco pid,command | grep jamfHelper | awk '{ print $1; }' | xargs kill -9

# Stamp Log File - rsync Complete
echo " " >> "$destPath/UserData/${USER}Logs/$USER.log"
echo "=====Completed rSync BACKUP of $USER @ $(date)=====" >> "$destPath/UserData/${USER}Logs/$USER.log"


MESSAGE="The Backup is complete"

btnReturned=$("$JHELPER" -windowType utility -title "KISD Mac Systems Admin" -heading "User Back Up" -description "$MESSAGE" -button1 "OK" -defaultButton 1 -icon "$useIcon" -iconSize 64)

if [ "$btnReturned" == "0" ]; then
	exit 0
fi
