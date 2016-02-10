"""
Freddie Cox - 2016
Usage: ~/jss_networksegments.py <jss username> <csv file.csv>
"""
import argparse
import csv
import getpass
import sys
from string import Template
import requests

# Edit JSS URL Blow. The rest should be server agnostic.
JSSURL = 'https://jss.knoxschools.org:8443'

PARSER = argparse.ArgumentParser(description="JSS Network Segment Addition from CSV File")
PARSER.add_argument('username', help="Enter JSS API enabled User.")
PARSER.add_argument('file', type=argparse.FileType('rU'), help="CSV File to process")
ARGS = PARSER.parse_args()

class Jss(object):
    """Create a JSS Object for connecting to the server"""
    def __init__(self, user=None, password=None, resource=None):
        self.user = user
        self.password = password
        self.resource = resource

def post_by_name(jss_obj, name, xml_data):
    """POST data to JSS API URL and return it as a requests object"""
    search_uri = JSSURL + "/JSSResource/" + jss_obj.resource + "/name/" + str(name)

    try:
        search_results = requests.post(search_uri, auth=(jss_obj.user, jss_obj.password), data=xml_data)
        return search_results
    except requests.RequestException:
        print "[ERROR] Couldn't connect. Verify JSS Address is correct and try again."
        sys.exit(0)


def main():
    """Meat and potatoes. Connect to JSS"""
    username = ARGS.username
    passw = getpass.getpass("Enter JSS API User Password: ")
    jss_obj = Jss(user=username, password=passw, resource='networksegments')

    row_reader = csv.DictReader(ARGS.file)
    for row in row_reader:
        xml_template = Template('<network_segment>'
                                '<name>$name</name>'
                                '<starting_address>$start</starting_address>'
                                '<ending_address>$end</ending_address>'
                                '<distribution_point>$dp</distribution_point>'
                                '<url>$url</url>'
                                '<building>$bldg</building>'
                                '<override_buildings>$over_bldg</override_buildings>'
                                '<override_departments>$over_dept</override_departments>'
                                '</network_segment>')

        xml_upload = xml_template.safe_substitute(name=row['name'],
                                                  start=row['starting_address'],
                                                  end=row['ending_address'],
                                                  dp=row['distribution_point'],
                                                  url=row['url'],
                                                  bldg=row['building'],
                                                  over_bldg=row['override_buildings'],
                                                  over_dept=row['override_departments'])

        post = post_by_name(jss_obj=jss_obj, name=row['name'], xml_data=xml_upload)

        if post.status_code == 201:
            print "[INFO] " + row['name'] + " created!"
        elif post.status_code == 409:
            print "[ERROR] " + str(post.status_code) + \
                  " Object likely already exists. Check CSV & JSS."
        else:
            print "[ERROR] " + str(post.status_code) + \
                  " Check input file for errors or existing object in JSS and re-submit."
            # Uncomment below if you want to visually see your XML representation
            #print(xml_upload)

main()
