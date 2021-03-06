#!/usr/local/bin/python3
__author__ = 'Freddie Cox'
__version__ = '0.1'

import requests
import json
print('Returns Maximum of 50 results. This only shows iPad Software.')

appName = input('Which App Name? ')
searchUri = "https://itunes.apple.com/search?term=" + appName + "&entity=iPadSoftware"

searchResults = requests.get(searchUri)

jsonData = searchResults.json()
print('Results:', jsonData['resultCount'])

for i in jsonData['results']:
    print('iOS App Name:',i['trackCensoredName'])
    print('Bundle ID:',i['bundleId'])
