import requests
import csv
import time
import getpass
import argparse
from string import Template

# Edit JSS URL Blow. The rest should be server agnostic.
jssURL = 'https://jss.pretendco.com:8443'

parser = argparse.ArgumentParser(description="JSS Network Segment Addition from CSV File")
parser.add_argument('username', help="Enter JSS API enabled User.")
parser.add_argument('file', type=argparse.FileType('rU'),help="CSV File to process")
args = parser.parse_args()

class jss(object):
    def __init__(self, user=None, password=None, id_num=None, resource=None):
        self.user = user
        self.password = password
        self.id_num = id_num
        self.resource = resource

    def post_by_name(self, user, password, name, resource, xmlData):
        searchURI = jssURL + "/JSSResource/" + resource + "/name/" + str(name)
        jsonHeaders = {'accept': 'application/json'}
        searchResults = requests.post(searchURI, auth=(user, password), data=xmlData)
        return searchResults

def main():

    jssObj = jss()
    username = args.username
    passw = getpass.getpass("Enter JSS API User Password: ")

   rowReader = csv.DictReader(args.file)
    for row in rowReader:
        xmlTemplate = Template('<network_segment>'
                               '<name>$name</name>'
                               '<starting_address>$start</starting_address>'
                               '<ending_address>$end</ending_address>'
                               '<distribution_point>$dp</distribution_point>'
                               '<url>$url</url>'
                               '<building>$bldg</building>'
                               '<override_buildings>$over_bldg</override_buildings>'
                               '<override_departments>$over_dept</override_departments>'
                               '</network_segment>')

        xmlTemplate.safe_substitute(name=row['name'])

        xmlUpload = xmlTemplate.safe_substitute(name=row['name'], start=row['starting_address'], end=row['ending_address'],
                                                dp=row['distribution_point'], url=row['url'], bldg=row['building'],
                                                over_bldg=row['override_buildings'], over_dept=row['override_departments'])

        post = jssObj.post_by_name(user=username, password=passw, name=row['name'],resource='networksegments',xmlData=xmlUpload)

        if post.status_code == 201:
            print("[INFO] " + row['name'] + " created!")
        else:
            print("[ERROR] " + str(post.status_code) + "Check input file for errors and re-submit.")
            # Uncomment below if you want to visually see your XML representation
            #print(xmlUpload)
  
main()
