public-jss
==========

JSS scripts and whatnot

This is my public dumping grounds for scripts, extension attributes, etc that others might find interesting.

Please feel free to submit ideas for improvments and bugs!

### jss_network_segments.py
Need to add a large range of network segments to your JSS Casper Server? jss_NetworkSegments.py allows you to create a spreadsheet (csv) of required information and upload it to your JSS using the JAMF JSS API. 

Notes: Written for Python 3.4, requires requests module. (pip install requests)

Step 1: Create a CSV File with the following columns: 
  starting_address	ending_address	building	id	distribution_point	url	name	override_buildings	override_departments

Fill in your needed data. 

Step 2: Download Script and run using the following syntax:

`python3.4 ~/Path/to/Script/jss_network_segments.py <JSS API Username> </Path/to/CSV/file.csv>`

Example: `python3.4 ~/Desktop/jss_network_segments.py casperuser ~/Desktop/NetworkSegments.csv``

### printer_destroyer.sh
Use this script to remove a printer by IP address that may have been manually configured in your environment. Add the script to casper and use parameter 4 as the IP address field for removal. 

Next, add the script to your policy. I choose to run this "before" my other scripts in the policy. Add the IP address to the correct paramter field and you're off to the races!




