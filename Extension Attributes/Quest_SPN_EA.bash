#!/bin/bash
#
# Freddie Cox - Nov. 12, 2011 
# For Knox County Schools
# 
# Check's Service Principal Name for 
# host machine and reports back to JSS
# if there's an error which gets fixed
# via a policy 

vastool -u domjoin -w kcs123z attrs host/ serviceprincipalname
StatusResult=$?

if [ $StatusResult != 0 ]; then
   SPNStatusResult="ResetSPN"
else
   SPNStatusResult="SPN OK"
fi

echo "<result>$SPNStatusResult</result>"
