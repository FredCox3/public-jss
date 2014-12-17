# Freddie Cox - December 15, 2014
# Uses Quest AD Commandlets to Query AD and build class data
# Version Info: 1.1 (12/16/2014)
#
# Change Log:
# 12-15-2014 - Initial Code Release.
# 12-16-2014 - Updated course name logic to fix bug where previous grade number was being uploaded. Added additional 
#              logging and made code more portable by adding variable for site name and ID number.
# 12-17-2014 - Sanitized Code to upload to github.

# Add Required SnapIn
Add-PSSnapin Quest.ActiveRoles.ADManagement

# Variables
#

# Set Status variable blank and delcare type
[string]$status = $null

# Stored Credentials for Silent Run. Can remove or comment out
# and it will prompt for each API call
$username = 'APIUsername'											# Change based on the Casper API Account
$password = 'OpenSesame' 											# Change based on the Casper API Account
$secPw = ConvertTo-SecureString $password -AsPlainText -Force
$creds = New-Object pscredential -ArgumentList $username,$secPw		 
$focusSiteID = "1"													# Change based on the site ID.
$focusSiteName = "SITE1"											# Change based on the site ID Name.
$jssAddress = "https://jss.company.com:8443"
$apiURL = "/JSSResource/classes/name/"

# Directory Variables												# Change these to your environment
$xmlWorkingDir = "D:\xml\"
$classWorkingDir = "D:\classes\"
$courseWorkingDir = "D:\courses\"
$classLogPath = "D:\logging\"

# File Variables
$deletedLogFile = $classLogPath + "casperFocus_AD_Sync.log"

# Other Variables
$grades = '09','10','11','12'
$classHash = @{}
$ou = "OU=Students,DC=school,DC=edu"

# Debug Logging with Start-Transcript
# Uncomment to view STDOUT when running as a service 
#Start-Transcript -Path $classLogPath\ad_class.log


# Log the start time
$status = "$(get-date) [INFO] ---------- Starting Casper Focus Class update Run ----------" 
$status | Out-File -FilePath $deletedLogFile -Append

# Query AD and build grade level groups
# Our environment has the "title" attribute as
# as the student's grade level. Your environment may be different.
$ad_classes = Get-QADUser -SizeLimit 0 -Enabled -SearchRoot $ou | Select samAccountName,department,title | Sort Title

# Loop through the grades to build individual grade arrays
foreach ($grade in $grades){$classHash[$grade] = @() }

# Loop through each student to put them in the correct class array
Foreach ($student in $ad_classes){
    #Write-Host $student.Title $student.SamAccountName
    $classHash[$student.Title] += $student.SamAccountName
}

# From the classHash hastable, loop through each object to build XML for each grade
$classHash.Keys | ForEach-Object {
    $currentGrade = $_
    $courseName = "$($currentGrade)th Grade"
    Write-Host $currentGrade
    $status = "$(get-date) [INFO] Proceessing $courseName"
    $status | Out-File -FilePath $deletedLogFile -Append

    # Setting File Name and Path
    $xmlPath = $xmlWorkingDir + $currentGrade + "_th_grade" + ".xml"
    
    #Build Some XML for upload
    $xmlWriter = New-Object System.XMl.XmlTextWriter($xmlPath,$Null)
    $xmlWriter.WriteComment('Austin East HS Grade: ' + $currentGrade)
    $xmlWriter.WriteComment('Write Date: ' + $(Get-Date))
    # Root Element - Class
    $xmlWriter.WriteStartElement('class')
      $xmlWriter.WriteElementString('name',"$($courseName)")
      $xmlWriter.WriteElementString('type',"Usernames")
      $xmlWriter.WriteStartElement('site')
        $xmlWriter.WriteElementString('id',"$($focusSiteID)")
        $xmlWriter.WriteElementString('name',"$($focusSiteName)")
        # Close the site element
        $xmlWriter.WriteEndElement()
    $xmlWriter.WriteStartElement('students')

    # Loop through and add students
    foreach ($i in $classHash.Item($_)) {
            $xmlWriter.WriteElementString('student',$i) 
    }

    # Finalize the document:
    # Close the Student Element
    $xmlWriter.WriteEndElement()
    $xmlWriter.WriteStartElement('teachers')

        # Add requested teachers to all classes

        # John Samples - Assistant Principal 
        $xmlWriter.WriteElementString('teacher',"jsamples")

        # Hannah Montana- Technology Coach 
        $xmlWriter.WriteElementString('teacher',"hmontanta")

        # Walter White - Adjunct Chemistry Faculty
        $xmlWriter.WriteElementString('teacher',"wwhite")
        $xmlWriter.WriteEndElement()

# Flush the XML Data Stream and Close the File
$xmlWriter.Flush()
$xmlWriter.Close()

# Build and Write the class URI for console logging of progress
[string]$classUri = $jssAddress + $apiURL + $courseName
Write-Host $classUri

try {
Invoke-RestMethod -uri "$classUri" -Credential $creds -Method GET -Headers @{"Accept"="application/json"}
# Course Exists. Update it with PUT
# Invoke-RestMethod doesn't log errors well. Catch the error and report it to log file or write success.
    try {
    Invoke-RestMethod -uri "$classUri" -Credential $creds -Method PUT -ContentType "text/xml" -InFile $xmlPath
    # Uncomment below for debugging success
    $status = "$(get-date) [INFO] Existing Class Upload Successful for $courseName"
    $status | Out-File -FilePath $deletedLogFile -Append
        }
    catch {
    # Report upload/update Errors to log file here
    $status = "$(get-date) [ERROR] Existing Class update FAILED for $courseName"
    $status | Out-File -FilePath $deletedLogFile -Append
        }
    }
catch {
    try {
    # Course Doesnt' Exist. POST Course
    Invoke-RestMethod -uri "$classUri" -Credential $creds -Method POST -ContentType "text/xml" -InFile $xmlPath
    $status = "$(get-date) [INFO] New Class Upload Successful for $courseName"
    $status | Out-File -FilePath $deletedLogFile -Append
    }
    catch {
    # Report upload/update Errors to log file here
    $status = "$(get-date) [ERROR] New Class Upload FAILED for $courseName"
    $status | Out-File -FilePath $deletedLogFile -Append
    }
  # Close the second nested Catch 
  }

}

# End of Script Report end time to log file
$status = "$(get-date) [INFO] ---------- Ending Casper Focus Class update Run ----------" 
$status | Out-File -FilePath "$deletedLogFile" -Append
