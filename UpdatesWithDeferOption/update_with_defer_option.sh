#!/bin/sh

file=$(find /Library/Application\ Support/JAMF/bin/KISDColorseal.png)
if [ ! -z "$file" ]
then
	useIcon=/Library/Application\ Support/JAMF/bin/KISDColorseal.png
else
	useIcon=/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns
fi

mkdir "/Library/Application Support/JAMF/bin/updates"

JHELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

function runUpdates {
	echo "Run Updates"

MESSAGE="Updates are being downloaded.
Installation will begin shortly."

	"$JHELPER" -windowType utility \
	-title "KISD Mac Systems Admin" \
	-heading "Updates Installing" \
	-description "$MESSAGE" \
	-lockHUD \
	-icon "$useIcon" \
	-iconSize 64 &

	softwareupdate -d

	ps axco pid,command | grep jamfHelper | awk '{ print $1; }' | xargs kill -9

MESSAGE="Updates are being installed.
Your computer will restart when updates are complete."

	"$JHELPER" -windowType utility \
	-title "KISD Mac Systems Admin" \
	-heading "Updates Installing" \
	-description "$MESSAGE" \
	-lockHUD \
	-icon "$useIcon" \
	-iconSize 64 &

		softwareupdate -ia

		ps axco pid,command | grep jamfHelper | awk '{ print $1; }' | xargs kill -9

	rm -rf "/Library/Application Support/JAMF/bin/updates"

	echo "Restarting"
	shutdown -r now
}

function allowDeferral {

MESSAGE="Important updates are available for your computer.
Save any unsaved work and click update.
Your computer will resart when updates are complete.
Click Update to install now.
Click Defer to install later.
You have ${deferPhrase} remaining."

response=$("$JHELPER" -windowType utility \
-title "KISD Mac Systems Admin" \
-heading "Updates Available" \
-description "$MESSAGE" \
-button1 "Update" \
-button2 "Defer" \
-defaultButton 1 \
-lockHUD \
-icon "$useIcon" \
-iconSize 64)

if [ "$response" == "0" ]; then
	runUpdates
else
	echo "deferment"
fi

exit 0
}

function requireUpdate {

MESSAGE="Important updates are available for your computer.
You have used all your deferments.
Save any unsaved work and click update.
Your computer may resart if an update requires a restart.
Click update to install updates OR
The updates will install automatically in 2 mins."

response=$("$JHELPER" -windowType utility \
-title "KISD Mac Systems Admin" \
-heading "Updates Available" \
-description "$MESSAGE" \
-button1 "Update" \
-defaultButton 1 \
-timeout 120 \
-countdown \
-lockHUD \
-icon "$useIcon" \
-iconSize 64)

if [ "$response" == "0" ]; then
	runUpdates
fi

exit 0
}

file="/Library/Application Support/JAMF/bin/updates/updatedeferred1.reciept"
if [ -f "$file" ];then
	echo "Reciept 1 Present"
	file="/Library/Application Support/JAMF/bin/updates/updatedeferred2.reciept"
	if [ -f "$file" ];then
		echo "Reciept 2 Present"
		file="/Library/Application Support/JAMF/bin/updates/updatedeferred3.reciept"
		if [ -f "$file" ];then
			echo "Reciept 3 Present"
			echo "require install"
			requireUpdate
		else
				echo "Touch Reciept 3"
				touch "/Library/Application Support/JAMF/bin/updates/updatedeferred3.reciept"
				deferPhrase="1 deferment"
				allowDeferral
		fi
	else
		echo "Touch Receipt 2"
		touch "/Library/Application Support/JAMF/bin/updates/updatedeferred2.reciept"
		deferPhrase="2 deferments"
		allowDeferral
	fi
else
	echo "Touch Reciept 1"
	touch "/Library/Application Support/JAMF/bin/updates/updatedeferred1.reciept"
	deferPhrase="3 deferments"
	allowDeferral
fi



exit 0
