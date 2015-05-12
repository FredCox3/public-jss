<#
    .SYNOPSIS 
      Takes a CSV File export from our SIS and builds a Casper Focus Class
    .DESCRIPTION
      This script reads an export of students and classes and then builds a Casper Focus Class from that data.
         
    .EXAMPLE
     jss_FocusClassfromCSV_PSU -username APIUser -password APIPassword -logpath D:\Focus -csvFile D:\Focus\classes.csv

    .NOTES 
     jss_FocusClassfromCSV.ps1

     Freddie Cox - December 10, 2014
     For Knox County Schools
 
     Notes: 
     - API Account is limited only to listed Site in the JSS. Will fail with others.
     - XML Is hard coded for Site, otherwise, the code is mostly portable.
     - No alerts at this time, maybe one day.

    Version Info: 1.1 (12/15/2014)

     Change Log:
     12-10-2014 - Initial Code Release: Support for logging, new class creation and self clean up of files > 30 days.
     12-15-2014 - Changed Log name and how Password is handled
     01-27-2015 - Remove CSV Files to avoid duplicate user ID issues.
     05-12-2015 - Added parameters, updated variable logic to include less static variables. 100% more reticulated splines.
#>

Param(
    [parameter(Mandatory=$true, HelpMessage="Enter Password for API Enabled User")]
        [alias("p","pass")]
        [String[]]$password,

    [parameter(Mandatory=$true, HelpMessage="Enter Username for API Enabled User")]
        [alias("u","user")]
        [String[]]$username,

    [parameter(Mandatory=$true, HelpMessage="Enter Path for XML Files and Logs.")]
        [String[]]$logpath,

    [parameter(Mandatory=$true, HelpMessage="Enter Path for CSV Import File.")]
        [alias("f","file")]
        [String[]]$csvFile,

    [parameter(Mandatory=$true, HelpMessage="Enter JSS URL and port. E.g. http://jssurl.company.com:8443.")]
        [alias("j","jss")]
        [String[]]$jssUrl,

    [parameter(Mandatory=$false, HelpMessage="Enter Site ID from JSS. E.g. 27")]
        [String[]]$siteID = "-1",
    
    [parameter(Mandatory=$false, HelpMessage="Enter Site Name. E.g. HighSchool ")]
        [String[]]$siteName = "None"
)


# Variables
[string]$status = $null

# Stored Credentials for Silent Run
$secPw = ConvertTo-SecureString $password[0] -AsPlainText -Force
$creds = New-Object pscredential -ArgumentList $username,$secPw

# Directory Variables
$xmlWorkingDir = '{0}\{1}\xml\' -f [string]$logpath,$siteName[0]
$classWorkingDir = '{0}\{1}\classes\' -f [string]$logpath,$siteName[0]
$courseWorkingDir = '{0}\{1}\courses\' -f [string]$logpath,$siteName[0]
$classLogPath = '{0}\{1}\logging\' -f [string]$logpath,$siteName[0]
$deletedLogFile = '{0}\{1}\casperFocusClasses.log' -f [string]$logpath,$siteName[0]

# File Variables
$csvExportFile = $csvFile

# Functions

function logData {
    param ( [string]$message)
    $status = "$(get-date) " + $message  
    $status | Out-File -FilePath $deletedLogFile -Append
}

function cleanCSV {
    
    if (Test-Path $classWorkingDir\* -Include *.csv) {
        Remove-Item $classWorkingDir* -Include *.csv
        logData -message "[INFO] Deleting CSV Files to avoid duplicates"
        }
    else {
        Write-Host "No CSVs Found to clean. Continuing."
    }
    
}

function fileTest {

    if (Test-Path $xmlWorkingDir) {
        Write-Host "XML Directory Exists. Continuing"
    }
    else{
        Write-Host "Creating XML Directory"
        New-Item -Path $xmlWorkingDir -ItemType directory
    }

    if (Test-Path $classWorkingDir) {
        Write-Host "Class Directory Exists. Continuing"
    }
    else{
        Write-Host "Creating Classes Directory"
        New-Item -Path $classWorkingDir -ItemType directory
    }

    if (Test-Path $classLogPath) {
        Write-Host "Logging Directory Exists. Continuing"
    }
    else{
        Write-Host "Creating Logging Directory"
        New-Item -Path $classLogPath -ItemType directory
    }
}

# Debugging with PS Transcript for headless rn
# Start-Transcript "$classLogPath\debug_Transcript.log"

# Log the start time
logData -message "[INFO] ---------- Starting Casper Focus Class update Run ----------"

fileTest

cleanCSV

# Check the directory exists
$dirCheck = Test-Path -Path $csvExportFile
Write-Host "Directory Check Status: $dirCheck"

if ($dirCheck = $false) {
    logData -message "[ERROR] Directory check faild. Terminating Script. No changes made."
    exit
}
else {

logData -message "[INFO] Directory is accessible: $dirCheck"

# Loop through the CSV File and break it into files for each course
$csvFile = Import-Csv $csvExportFile | foreach {
    # Create File Based on Course Number
    $new_file = $_."Teacher login" + "_" + $_.Term + "_P" + $_.Period
    Export-CSV -NoTypeInformation -Path (Join-Path -Path $classWorkingDir -ChildPath "$($new_file).csv") -InputObject $_ -Append
}

logData -message "[INFO] Finished CSV Import. Starting XML Builds."

# Now, import each new csv file and get it ready convert to xml
Get-ChildItem -Path $classWorkingDir -Filter *.csv| ForEach-Object {
    $LastWrite = $_.LastWriteTime
    $LoopCSVFile = Import-CSV $_.FullName
    $courseName = $siteName[0] + " - " +$LoopCSVFile.Term[0] + "P" + $LoopCSVFile."Period"[0] + " " + $LoopCSVFile."Teacher last name"[0] + " " + $LoopCSVFile."Teacher first name"[0]

#Build Some XML for upload
$xmlPath = $xmlWorkingDir + $courseName + ".xml"
$xmlWriter = New-Object System.XMl.XmlTextWriter($xmlPath,$Null)

# Adding Comments to XML File
$xmlWriter.WriteComment('Last Update: ' + $LastWrite.ToLocalTime())
$xmlWriter.WriteComment('School: ' + $($LoopCsvFile.School[0]))
$xmlWriter.WriteComment('Teacher Name: ' + $($LoopCsvFile."Teacher first name"[0]) + ' ' + $($LoopCsvFile."Teacher last name"[0]))
$xmlWriter.WriteComment('Course Description: ' + $($LoopCsvFile.Description[0]))
$xmlWriter.WriteComment('Course ID: ' + $($LoopCSVFile."Course no."[0]))

# Root Element - Class
$xmlWriter.WriteStartElement('class')
    $xmlWriter.WriteElementString('name',"$($courseName)")
    $xmlWriter.WriteElementString('type',"Usernames")
    $xmlWriter.WriteStartElement('site')
        $xmlWriter.WriteElementString('id',$siteID[0])
        $xmlWriter.WriteElementString('name',$siteName[0])
        # Close the site element
        $xmlWriter.WriteEndElement()
    $xmlWriter.WriteStartElement('students')

# Loop through each line of the file and grab the students login id to build the xml body
foreach ($i in $LoopcsvFile) {
        $xmlWriter.WriteElementString('student',$i."Student login") 
}
    # Finalize the document:
    # Close the Student Element
    $xmlWriter.WriteEndElement()
    $xmlWriter.WriteStartElement('teachers')

        # Add Assigned Teacher to the class from Export
        $xmlWriter.WriteElementString('teacher',$i."Teacher login")

        # Add requested teachers to all classes

        # Jane Samples - Assistant Principal
        #$xmlWriter.WriteElementString('teacher',"jsamples01")

        $xmlWriter.WriteEndElement()

# Flush the XML Data Stream and Close the File
$xmlWriter.Flush()
$xmlWriter.Close()

[string]$classUri = "{0}/JSSResource/classes/name/{1}" -f [string]$jssUrl,$courseName
Write-Host $classUri

logData -message "[INFO] Finished XML Build. Trying Upload at $classUri."

try {
Invoke-RestMethod -uri "$classUri" -Credential $creds -Method GET -Headers @{"Accept"="application/json"}

# Course Exists. Update it with PUT
# Invoke-RestMethod doens't log errors well. Catch the error and report it to log file or write success.
    try {
    Invoke-RestMethod -uri "$classUri" -Credential $creds -Method PUT -ContentType "text/xml" -InFile $xmlPath
    # Uncomment below for debugging success
    logData -message "[INFO] Existing Class Upload Successful for $courseName"
        }
    catch {
    # Report upload/update Errors to log file here
    logData -message "[ERROR] Existing Class update FAILED for $courseName"
        }
    }
catch {
    try {
    # Course Doesnt' Exist. POST Course
    Write-Host "Attempting POST"
    Write-Host $xmlPath
    Invoke-RestMethod -uri "$classUri" -Credential $creds -Method POST -ContentType "text/xml" -InFile $xmlPath
    logData -message "[INFO] New Class Upload Successful for $courseName"
    }
    catch {
    # Report upload/update Errors to log file here
    logData -message "[ERROR] New Class Upload FAILED for $courseName"
    }
  # Close the second nested Catch 
  }
# Close the CSV Build Function
}

# Clean Up Old files

$oldXMLFiles = Get-ChildItem $xmlWorkingDir -Filter *.xml | ? {
  -not $_.PSIsContainer -and ((get-date)-$_.LastWriteTime).days -gt 30
}

ForEach ($file in $oldXMLFiles) {

    Write-Host $file.Name
    # Build the URI again for the old classes
    $removeCourseName = ($file.BaseName)
    [string]$removeclassUri = "{0}/JSSResource/classes/name/{1}" -f [string]$jssUrl,$removeCourseName
    Write-Host $removeclassUri

    # Reporting what I am about to do
    logData -message "[INFO] Remove Pending for $($file.FullName) - $removeclassUri"

    # Actually Deleting Things here
    # Delete from JSS Classes
    try {
       $restOutput = Invoke-WebRequest -uri "$removeClassUri" -Credential $creds -Method DELETE
       # Success
       logData -message "[DROP] $removeCourseName Successfully deleted from the JSS"

       # Delete the file so it won't upload again
       $file.FullName | Remove-Item
    }
    catch {
        # Fail - Report it to log file
       logData -message "[ERROR] Error Removing Class from JSS $($removeclassUri) with name $($removeCourseName)"
    }
   
}

# End of Script Report end time to log file

logData -message "[INFO] ---------- Ending Casper Focus Class update Run ----------"

} # Closing Else Statement 
