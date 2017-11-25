#!/bin/sh

# List any CS5 or higher products.

if [ -d /Library/Application\ Support/regid.1986-12.com.adobe/ ] ; then

# Read each each found file and add its product to a list

for AFILE in /Library/Application\ Support/regid.1986-12.com.adobe/*

do
PRODUCT=$( sed -n -e 's/.*<swid:product_title>\(.*\)<\/swid:product_title>.*/\1/p' "$AFILE" )
LICENSE=$( sed -n -e 's/.*<swid:activation_status>\(.*\)<\/swid:activation_status>.*/\1/p' "$AFILE" )
SERIAL=$( sed -n -e 's/.*<swid:serial_number>\(.*\)<\/swid:serial_number>.*/\1/p' "$AFILE" )
PRODUCTLIST="$PRODUCTLIST$PRODUCT $LICENSE $SERIAL"$'\n'
done

fi

# List any CS4 products.

if [ -d /Users/Shared/Adobe/ISO-19770/ ] ; then

# Read each found file add its product to the list

for AFILE in /Users/Shared/Adobe/ISO-19770/*

do
PRODUCT=$( sed -n -e 's/.*<sat:product_title>\(.*\)<\/sat:product_title>.*/\1/p' "$AFILE" )

# Some products use a different version of SWID Tag where "sat:product_title" isn't valid.
# If "sat:product_title" isn't found in the tag then assume "product".

if [ "$PRODUCT" = "" ] ; then
PRODUCT=$( sed -n -e 's/.*<product>\(.*\)<\/product>.*/\1/p' "$AFILE" )
SUITE=$( sed -n -e 's/.*<part_of_suite>\(.*\)<\/part_of_suite>.*/\1/p' "$AFILE" )

# Some products such as Acrobat Pro may exist but this older version
# of SWID Tag will only indicate that it was part of a suite or standalone.
# Report if the product is part of a suite.

if [ "$SUITE" = "true" ] ; then
PRODUCT="$PRODUCT is part of an unknown CS4 suite"
fi
fi
LICENSE=$( sed -n -e 's/.*<sat:activation_status>\(.*\)<\/sat:activation_status>.*/\1/p' "$AFILE" )
PRODUCTLIST="$PRODUCTLIST$PRODUCT $LICENSE"$'\n'
done

fi

# Reports the list to the JSS.

echo "<result>$PRODUCTLIST</result>"
