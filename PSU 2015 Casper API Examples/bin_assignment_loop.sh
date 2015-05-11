#!/bin/bash

# Variables 
INPUT="/Users/username/Desktop/bin_assignment_sample.csv"
binID="32"

# Setup File Seperators
OLDIFS=$IFS
IFS=,
JSSURL="https://jssurl.com:8443/JSSResource/computers/serialnumber/"

# Create Empty XML File to write/upload from below
XMLFILE=/tmp/bin_assignment.xml
touch $XMLFILE

# Loop through the CSV File listed as INPUT above. Submit to JSS via a PUT.
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99;}
while IFS=, read serial bin_number
do
	echo "$serial $bin_number"
	echo "<computer><extension_attributes><extension_attribute><id>$binID</id><name>Storage Bin</name><type>String</type><value>$bin_number</value></extension_attribute></extension_attributes></computer>" > $XMLFILE
	curl -k -v -u APIEnabledUser:APIEnabledUserPassword $JSSURL$serial -T $XMLFILE -X PUT

done < $INPUT

# Putting things back where we got them
IFS=$OLFIFS