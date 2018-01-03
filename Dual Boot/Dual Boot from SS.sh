#!/bin/bash

comModel=$(sysctl -n hw.model)

incompatableModel(){

	userSelect=$(osascript -e 'display dialog "Your computer model is incompatable with your selection. Please choose another or Cancel." buttons {"Try Again", "Cancel"} default button "Try Again"')

	if [ "$userSelect" == "button returned:Try Again" ]; then
			continue
		else
			echo "User Canceled."
			exit 0
		fi
}


echo "Windows only image"

bootCampStatus=""

bootCampStatus=$(diskutil list | grep "BOOTCAMP" | awk '{print $NF}')

apfsLocation=$(diskutil list | grep "Apple_APFS Container" | awk '{print $NF}')

coreCheck=$(diskutil cs list)

if [ "$coreCheck" != "No CoreStorage logical volume groups found" ]; then
	echo "CoreStorage enabled"
	osascript -e 'display dialog "Your computer has CoreStorage Enabled. \nPlease contact the JSS Administrator. \nExiting now." buttons {"Ok"} default button 1'

	exit 1
fi

if [ -n "$bootCampStatus" ]; then

	diskutil eraseVolume "Free Space" %noformat% /dev/$bootCampStatus

	sleep 3

	diskutil apfs resizeContainer /dev/$apfsLocation 0

	#diskutil mergePartitions JHFS+ "Macintosh HD" /dev/disk0s2 /dev/$bootCampStatus
else
	echo "No Bootcamp partition found"
fi

sleep 5

winUpdate="2017 Win10 50M_50W
2017 Win10 80M_20W
2017 Win10 40M_60W"

modelStatus=""
while [ -z "$modelStatus" ];do

	## Ask for selection from the list
value=$(/usr/bin/osascript << EOF
set list_contents to do shell script "echo \"$winUpdate\""
set selectedUpdate to paragraphs of list_contents
tell application "System Events"
activate
choose from list selectedUpdate with prompt "Choose a computer Model and Partition"
end tell
EOF)

if [ "$value" == "false" ]; then
	echo "User exited."
	exit 0
fi

echo $comModel

case $value in
'2017 Win10 50M_50W')
	echo "2017 Win10 50M_50W"
	if [[ $comModel == "MacBookPro14,1" ]]; then
		echo "Model is Compatable"
		modelStatus="Compatable"
		installPackage="/Volumes/a-share-name/2017/win10_2017MBP_50M_50W_7_18.pkg"
	else
		echo "Model is Not Compatable"
		incompatableModel
	fi
	;;
'2017 Win10 80M_20W')
	echo "2017 Win10 80M_20W"
	if [[ $comModel == "MacBookPro14,1" ]]; then
		echo "Model is Compatable"
		modelStatus="Compatable"
		installPackage="/Volumes/a-share-name/2017/win10_2017MBP_80M_20W_7_18.pkg"
	else
		echo "Model is Not Compatable"
		incompatableModel
	fi
	;;
'2017 Win10 40M_60W')
	echo "2017 Win10 40M_60W"
	if [[ $comModel == "MacBookPro14,1" ]]; then
		echo "Model is Compatable"
		modelStatus="Compatable"
		installPackage="/Volumes/a-share-name/2017/win10_2017MBP_20M_80W_7_18.pkg"
	else
		echo "Model is Not Compatable"
		incompatableModel
	fi
	;;
esac
done

userName="ausername"
userPass="apassword"
shareName="apath/tothe/share"
whereToMount="/Volumes/a-share-name"

mkdir $whereToMount

sleep 2

mount_smbfs //$userName:$userPass@$shareName $whereToMount

sleep 2

installer -pkg $installPackage -target /Volumes/Macintosh\ HD &

#Window Title
title="Install In Progress"

#Window Heading
heading="Installing Windows...."

description="Setting up....."

/Volumes/a-share-name/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -windowPosition centre -title "$title" -alignHeading left -heading "$heading" -alignDescription left -description "$description" -lockHUD -icon /Volumes/jssdualboot/KISDWindowsIcon.png &

sleep 60

ps axco pid,command | grep jamfHelper | awk '{ print $1; }' | xargs kill -9

#Window Title
title="Install In Progress"

#Window Heading
heading="Installing Windows...."

description="Installing....This will take approx. 20mins."

/Volumes/a-share-name/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -windowPosition centre -title "$title" -alignHeading left -heading "$heading" -alignDescription left -description "$description" -lockHUD -icon /Volumes/jssdualboot/KISDWindowsIcon.png &

sleep 5

ps axco pid,command | grep jamfHelper | awk '{ print $1; }' | xargs kill -9

osascript -e 'tell application "Terminal" to do script "tail -F /tmp/winclone_package.log"'

sleep 1

open -a Terminal

run="yes"

while [ "$run" = "yes" ]
do
    sleep 10

	file=$(find /tmp/PKInstallSandbox.*)
    if [ -z "$file" ]
    then
	    run="no"
    fi

done

ps axco pid,command | grep Terminal | awk '{ print $1; }' | xargs kill -9

#Window Title
title="Install Complete"

#Window Heading
heading="Windows Install Complete"

description="Click Continue then Restart the computer"

button=$(/Volumes/a-share-name/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -windowPosition centre -title "$title" -alignHeading left -heading "$heading" -alignDescription left -description "$description" -lockHUD -icon /Volumes/jssdualboot/KISDWindowsIcon.png -button1 "Continue")

if [ "$button" == "0" ]; then

open -b com.apple.systempreferences /System/Library/PreferencePanes/StartupDisk.prefPane &

sleep 1

exit 0

fi
