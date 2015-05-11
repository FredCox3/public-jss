This script requires an input CSV File with a title column labeled "serial_number"

Make sure to adjust the JSS URL to that of your JSS as I am too lazy to create a plist.

##REQUIRED

CSV File with serial numbers of your duplicates. 
I create this by running the following mysql query:

`use jamfsoftware;` 

`SELECT serial_number, COUNT(*) c FROM jamfsoftware.computers_denormalized GROUP BY serial_number HAVING c > 1;`

##OPTIONALS
	-u Username of API Enabled user account
	-p Password of API Enabled user account
	-l Log-Only. No changes are made to your JSS.
