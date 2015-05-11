#!/usr/local/bin/python3

import sys
import requests
import argparse
import plistlib
import time
import json
import csv

jssURL = "https://jssurl.com:8443"

class ArgParser(object):
    def __init__(self):
        parser = argparse.ArgumentParser(description="What CSV File do you want to process?")
        parser.add_argument('file', type=argparse.FileType('rU'), help="Path to CSV with serials. Column serial_number")
        parser.add_argument('-u', '--user', type=str, default=None, help="JSS API Username")
        parser.add_argument('-p', '--passw', type=str, default=None, help="JSS API Password")
        parser.add_argument('-l', '--logonly', help='Log Only. Do not delete object.', action="store_true", )

        args = parser.parse_args()
        self.logonly = args.logonly
        self.username = args.user
        self.password = args.passw
        self.file = args.file

        if self.logonly:
            print("Log only flag set")
        else:
            pass

def main():
    args = ArgParser()
    jsonheaders = {'accept': 'application/json'}
    importfile = args.file
    rowReader = csv.DictReader(importfile)

    if args.username is None or args.password is None:
        print("ERROR: Please supply username and password using -u and -p option")
        sys.exit()
    else:
        pass

    for row in rowReader:
        serialNum = (row["serial_number"])
        # Build the JSS Search URI
        searchUri = jssURL + "/JSSResource/computers/match/" + serialNum
        print("Removing Duplicates for " + serialNum)

        # Send GET request
        searchResults = requests.get(searchUri, auth=(args.username, args.password), headers=jsonheaders)

        # Load the Search Results as a json file
        jsonData = searchResults.json()

        if len(jsonData['computers']) != 2:
            print("No Duplicate Found for " + serialNum + ". My job here is done!")
            continue
        else:
            # Loop through entries to determine newest and get data from oldest
            jssid = ()
            id = []
            username = []
            report_date = []
            report_date_obj2 = []
            asset_tag = []
            bin_number = []

            for i in jsonData['computers']:
                jssid = (i['id'])
                print("JSSID: ", + jssid)
                idUri = jssURL + "/JSSResource/computers/id/" + str(jssid) + "/subset/General&Location&extension_attributes"
                loopCall = requests.get(idUri, auth=(args.username, args.password), headers=jsonheaders)

                # Append to respective variables.
                id.append(loopCall.json()['computer']['general']['id'])
                username.append(loopCall.json()['computer']['location']['username'])
                report_date = loopCall.json()['computer']['general']['report_date']
                asset_tag.append(loopCall.json()['computer']['general']['asset_tag'])

                # Create time as object, not string so we can do some logic on it later.
                report_date_obj = time.strptime(report_date, "%Y-%m-%d %H:%M:%S")
                report_date_obj2.append(report_date_obj)

                # Loop through the extension attributes until you find one with expected ID
                # then append that ID's value so we can add it to the new record.
                for c in loopCall.json()['computer']['extension_attributes']:
                    if c['id'] == 32:
                        bin_number.append(c['value'])

            # Expect the first record (smallest ID) to be the oldest check-in. If not, report.

            deleteURI = ()

            if report_date_obj2[0] < report_date_obj2[1]:
                print("Old Computer:", id[0], asset_tag[0], username[0], bin_number[0])
                print("New Computer:", id[1], asset_tag[1], username[1], bin_number[1])
                updateURI = jssURL + "/JSSResource/computers/id/" + str(id[1])
                deleteURI = jssURL + "/JSSResource/computers/id/" + str(id[0])
                xmlData = "<computer><general><asset_tag>" + asset_tag[
                    0] + "</asset_tag><site><id>-1</id><name>None</name></site></general><location><username>" + \
                          username[
                              0] + "</username></location><extension_attributes><extension_attribute><name>Storage Bin</name><type>String</type><value>" + \
                          bin_number[0] + "</value></extension_attribute></extension_attributes></computer>"

                # Delete Old Duplicate Record first, otherwise PUT will fail.
                if args.logonly:
                    print("LOGONLY Flag Set. No changes made to ID:",id[0])
                else:
                    # Help out the impatient human.
                    print("Deleting old record. This could take some time. Delete ID:", id[0])
                    print("URL Requested for Delete: " + deleteURI)
                    delReq = requests.delete(deleteURI, auth=(args.username,args.password), timeout=240)

                    # Expect status code of 200. If something else, report it.
                    if int(delReq.status_code) == 200:
                        print("Delete Successful! Status Returned:", delReq.status_code)
                    else:
                        print("Delete Failed! Status Returned:", delReq.status_code)

                    # Put New Info Up not that duplicate has been removed.
                    print("URL Requested for update: " + updateURI)
                    putReq = requests.put(updateURI, auth=(args.username, args.password), data=xmlData, timeout=240)

                    # Expect Status Return of 201. If something else, report it.
                    if int(putReq.status_code) != 201:
                        print("Error Occurred Updating! Status Returned:", putReq.status_code)
                    else:
                        print("Update Successful! Status Returned:", putReq.status_code)
            else:
                print("Unexpected result. Manually inspect duplicates.")


if __name__ == "__main__": main()