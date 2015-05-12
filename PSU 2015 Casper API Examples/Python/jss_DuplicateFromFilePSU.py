#!/usr/local/bin/python3

import sys
import requests
import argparse
import time
import json
import csv
import xml.etree.cElementTree as ET

jssURL = "https://jssurl.com:8443"

class ArgParser(object):
    def __init__(self):
        parser = argparse.ArgumentParser(description="JSS Duplicate Cleanup.", epilog="You can export a list from your MySQL Server hosting the JSS Database. See GitHub Readme for more details.")
        parser.add_argument('file', type=argparse.FileType('rU'), help="Path to CSV file with serials.")
        parser.add_argument('-u', '--user', type=str, default=None, help="JSS API Username")
        parser.add_argument('-p', '--passw', type=str, default=None, help="JSS API Password")
        parser.add_argument('-l', '--logonly', help='Log Only. Do not delete object.', action="store_true", )

        args = parser.parse_args()
        self.logonly = args.logonly
        self.username = args.user
        self.password = args.passw
        self.file = args.file

        if self.logonly:
            print("[INFO] Log only flag set")
        else:
            pass

def main():
    args = ArgParser()
    jsonheaders = {'accept': 'application/json'}
    importfile = args.file
    rowReader = csv.DictReader(importfile)

    if args.username is None or args.password is None:
        print("[ERROR] Please supply username and password using -u and -p option")
        sys.exit()
    else:
        pass

    for row in rowReader:
        serialNum = (row["serial_number"])
        # Build the JSS Search URI
        searchUri = jssURL + "/JSSResource/computers/match/" + serialNum
        print("[INFO] Removing Duplicates for " + serialNum)

        # Send GET request
        searchResults = requests.get(searchUri, auth=(args.username, args.password), headers=jsonheaders)

        # Load the Search Results as a json file
        jsonData = searchResults.json()

        if len(jsonData['computers']) != 2:
            print("[INFO] No Duplicate Found for " + serialNum + ". My job here is done!")
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

            for record in jsonData['computers']:
                jssid = (record['id'])
                print("[INFO] JSSID: ", + jssid)
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
                print("[INFO] Old Computer:", id[0], asset_tag[0], username[0], bin_number[0])
                print("[INFO] New Computer:", id[1], asset_tag[1], username[1], bin_number[1])
                updateURI = jssURL + "/JSSResource/computers/id/" + str(id[1])
                deleteURI = jssURL + "/JSSResource/computers/id/" + str(id[0])

                # Build the XML Representation
                root = ET.Element("computer")
                general = ET.SubElement(root, 'general')
                ET.SubElement(general, 'asset_tag').text = asset_tag[0]
                site = ET.SubElement(general, 'site')
                ET.SubElement(site, 'id').text = "-1"
                ET.SubElement(site, 'name').text = "None"
                location = ET.SubElement(root, 'location')
                ET.SubElement(location,'username').text = username[0]
                ext_attrs = ET.SubElement(root, 'extension_attributes')
                ext_attr = ET.SubElement(ext_attrs, 'extension_attribute')
                ET.SubElement(ext_attr, 'id').text = "32"
                store_bin = ET.SubElement(ext_attr, 'name').text = "Storage Bin"
                ET.SubElement(ext_attr, 'value').text = bin_number[0]

                xmlData = ET.tostring(root)

                # Delete Old Duplicate Record first, otherwise PUT will fail.
                if args.logonly:
                    print("[INFO] LOG ONLY Flag Set. No changes made to ID:",id[0])
                else:
                    # Help out the impatient human.
                    print("[INFO] Deleting old record. This could take some time. Delete ID:", id[0])
                    print("[INFO] URL Requested for Delete: " + deleteURI)
                    delReq = requests.delete(deleteURI, auth=(args.username,args.password), timeout=240)

                    # Expect status code of 200. If something else, report it.
                    if int(delReq.status_code) == 200:
                        print("[INFO] Delete Successful! Status Returned:", delReq.status_code)
                    else:
                        print("[INFO] Delete Failed! Status Returned:", delReq.status_code)

                    # Put New Info Up not that duplicate has been removed.
                    print("[INFO] URL Requested for update: " + updateURI)
                    putReq = requests.put(updateURI, auth=(args.username, args.password), data=xmlData, timeout=240)

                    # Expect Status Return of 201. If something else, report it.
                    if int(putReq.status_code) != 201:
                        print("[ERROR] Error Occurred Updating! Status Returned:", putReq.status_code)
                    else:
                        print("[INFO] Update Successful! Status Returned:", putReq.status_code)
            else:
                print("[ERROR] Unexpected result. Manually inspect duplicates.")


if __name__ == "__main__": main()