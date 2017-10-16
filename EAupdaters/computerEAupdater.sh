#!/bin/sh

# Name: ComputerEAupdater.sh
# Date: 25 February 2016
# Pieced together by: Mike Donovan (mike.donovan@killeenisd.org)
# Purpose: used to read in computer EAs from a CSV file and update the record in the JSS
# Version: 1.0
#
# A good portion of this script is re-purposed from the script posted in the following JAMF Nation articles
# and Trey Howell's move records script on GitHub
#
#  https://github.com/jamftrey/JSS-API-SCRIPTS/blob/master/mvrecords.sh
#
#  https://jamfnation.jamfsoftware.com/discussion.html?id=13118#respond
#
#  https://jamfnation.jamfsoftware.com/discussion.html?id=13663
#


######## asks for JSS Address and adds variable
jssAddress="$(osascript -e 'Tell application "System Events" to display dialog "Enter JSS Address:" default answer "https://yourjssaddress.com:8443"' -e 'text returned of result' 2>/dev/null)"
if [ $? -ne 0 ]; then
    # The user pressed Cancel
    exit 1 # exit with an error status
elif [ -z "$jssAddress" ]; then
    # The user left the JSS address blank
    osascript -e 'Tell application "System Events" to display alert "You must enter a JSS Address; cancelling..." as warning'
    exit 1 # exit with an error status
fi

############## asks for username for API user and adds variable
jssAPIUsername="$(osascript -e 'Tell application "System Events" to display dialog "Enter API username:" with hidden answer default answer ""' -e 'text returned of result' 2>/dev/null)"
if [ $? -ne 0 ]; then
    # The user pressed Cancel
    exit 1 # exit with an error status
elif [ -z "$jssAPIUsername" ]; then
    # The user left the username blank
    osascript -e 'Tell application "System Events" to display alert "You must enter a JSS Username; cancelling..." as warning'
    exit 1 # exit with an error status
fi

######### asks for password for API users and adds variable
jssAPIPassword="$(osascript -e 'Tell application "System Events" to display dialog "Enter API Password:" default answer "" with hidden answer' -e 'text returned of result' 2>/dev/null)"
if [ $? -ne 0 ]; then
    # The user pressed Cancel
    exit 1 # exit with an error status
elif [ -z "$jssAPIPassword" ]; then
    # The user left the password blank
    osascript -e 'Tell application "System Events" to display alert "You must enter a JSS Password; cancelling..." as warning'
    exit 1 # exit with an error status
fi

######## asks for path to the CSV file
file="$(osascript -e 'Tell application "System Events" to display dialog "Enter path to the CSV file:" default answer "/Users/username/Desktop/ComputerEAupdate.csv"' -e 'text returned of result' 2>/dev/null)"
if [ $? -ne 0 ]; then
    # The user pressed Cancel
    exit 1 # exit with an error status
elif [ -z "$file" ]; then
    # The user left the file path blank
    osascript -e 'Tell application "System Events" to display alert "You must enter a file path; cancelling..." as warning'
    exit 1 # exit with an error status
fi


#Verify we can read the file
data=`cat $file`
if [[ "$data" == "" ]]; then
    echo "Unable to read the file path specified"
    echo "Ensure there are no spaces and that the path is correct"
    exit 1
fi

######## asks for EA id and adds variable
eaID="$(osascript -e 'Tell application "System Events" to display dialog "Enter JSS EA id:" default answer ""' -e 'text returned of result' 2>/dev/null)"
if [ $? -ne 0 ]; then
    # The user pressed Cancel
    exit 1 # exit with an error status
elif [ -z "$eaID" ]; then
    # The user left the EA id blank
    osascript -e 'Tell application "System Events" to display alert "You must enter an EA id; cancelling..." as warning'
    exit 1 # exit with an error status
fi

#Find how many computers to import
computerqty=`awk -F, 'END {printf "%s\n", NR}' $file`
echo "Computerqty= " $computerqty
#Set a counter for the loop
counter="0"


id=$((id+1))


#Loop through the CSV and submit data to the API
while [ $counter -lt $computerqty ]
do
    counter=$[$counter+1]
    line=`echo "$data" | head -n $counter | tail -n 1`
    serialNumber=`echo "$line" | awk -F , '{print $1}'`
    newEA=`echo "$line" | awk -F , '{print $2}'`

    echo "Attempting to update EA for $serialNumber"

    ## Create the xml file for later upload to the JSS
echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<computer>
 <extension_attributes>
    <extension_attribute>
      <id>${eaID}</id>
      <value>${newEA}</value>
    </extension_attribute>
  </extension_attributes>
</computer>" > /tmp/computerEAupdate.xml


## Upload xml to the JSS via API
curl -fsku "${jssAPIUsername}:${jssAPIPassword}" "${jssAddress}/JSSResource/computers/serialnumber/${serialNumber}" -T /tmp/ComputerEAupdate.xml -X PUT


## Check to see if we got a 0 exit status from the PUT command
    if [ $? == 0 ]; then
        echo "Computer \"$serialNumber\" updated"

    else
        #echo "Update failed"
        echo "Computer \"$serialNumber\" EA update failed serial number may not exist in the JSS."
        ## Clean up the xml file
        #rm -f "/tmp/ComputerEAupdate.xml" ### may want to keep this file for troubleshooting###
        exit 1
    fi
done

 ## Clean up the xml file
 rm -f "/tmp/ComputerEAupdate.xml"

exit 0
