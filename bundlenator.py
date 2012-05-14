#!/usr/bin/env python

'''
	1. 
	create folder structure
	Download list of games from website

	2.

	For each game in list:
		* Check to see if not downloaded already
		* If not then:
			download json of level
			download custom spritesheets
			download custom backgrounds
			download custom sfx
			download custom music
			download custom tilesheets
			download custom weapon spritesheets
			check for jump to level robot, if found for each level:
				load level as above. (recurse)
	
	3. 	
	write plist
	4.
	write consolidated games json
	5.
	write consolidated levels json 
'''


# Bundlenator - The Gamefroot IAP packaging tool
#
# By Sam Win-Mason (sam@albedogames.com)
# Copyright (c) 2012 Instinct Entertainment
# 
# Tested on Python 2.7
#  
# Bundlenator takes a GameFroot wp category name and fetches all
# resources and data for the games in that category. It bundles the
# data as a zip file ready for download as an in-app purchase.


"""
SYNOPSIS

    bundlenator [-h] [-v,--verbose] [--version] category_name endpoint_url bundle_output_path

DESCRIPTION
	
	usage: bundlenator [-h] [-v,--verbose] [--version] category_name endpoint_url bundle_output_path

EXAMPLES

    bundlenator feb_issue http://gamefroot.com ~/Desktop

AUTHOR

    Sam Win-Mason <sam@albedogames.com>

LICENSE

    Copyright (C) 2012 Instinct Entertainment Ltd

VERSION

	1.0
    
"""

import sys
import os
import traceback
import optparse
import time
import urllib
import json

# Some global config

GET_LEVELS_API_STRING = '?gamemakers_api=1&type=get_all_levels&category='


def loadGameData():

	global gamedata
	print "retrieving game list for category " + args[0] + "..."

	# get game data
	requestString = args[1] + GET_LEVELS_API_STRING + args[0]
	gameDataFH = urllib.urlopen(requestString)
	gamedata = json.load(gameDataFH)


def loadAsset(dirName, urlString):
	localFilePath = args[2] + "iap_bundle/" + dirName + "/" + os.path.split(urlString)[1]
	if(not os.path.exists(localFilePath)):
		try:
			inetFH = urllib.urlopen(urlString)
			print '[done]'
			localFH = open(localFilePath, 'w')
			localFH.write(inetFH.read())
		except Exception, e:
			raise
		else:
			pass
		finally:
			print '[saved]'



def loadGameAssets():
	print "retrieving game assets..."

	# for each level, load the assets
	for level in gamedata:
		print "retrieving assets for '" + level['title'] + "'..."
		# Thumb
		print "		downloading thumb..."
		loadAsset('thumbs',level['background'])
		print "		downloading map data"
		loadMapData(level['id'])
		

def loadMapData():
	pass	


def createDirectoryStructure():
	if(os.path.exists(args[2])):
		# Create directories
		print "creating bundle directory structure..."
		try:
			os.chdir(args[2])
			os.mkdir("iap_bundle")
			os.chdir("iap_bundle")
			os.mkdir("thumbs")
			os.mkdir("backgrounds")
			os.mkdir("characters")
			os.mkdir("tiles")
			os.mkdir("sfx")
			os.mkdir("music")
			os.mkdir("weapons")

		except Exception, e:
			print "There was an error creating bundle directories at the specifed path [Failwhale]"
		
	else :
		print 'specified path does not exist [Failwhale]'



def main ():

	global options, args

	print 'Bundlenator - The Gamefroot IAP packaging tool'

	# print 'Getting list of games from server ... ';
	
	# Create folder structure
	if(len(args) == 3):

		createDirectoryStructure()
		loadGameData()
		loadGameAssets()

	else:
		print "USAGE: bundlenator [-h] [-v,--verbose] [--version] category_name endpoint_url bundle_output_path"




if __name__ == '__main__':
    try:
        start_time = time.time()
        parser = optparse.OptionParser(
                formatter=optparse.TitledHelpFormatter(),
                usage=globals()['__doc__'],
                version='$Id: py.tpl 332 2008-10-21 22:24:52Z root $')
        parser.add_option ('-v', '--verbose', action='store_true',
                default=False, help='verbose output')
        (options, args) = parser.parse_args()
        #if len(args) < 1:
        #    parser.error ('missing argument')
        if options.verbose: print time.asctime()
        exit_code = main()
        if exit_code is None:
            exit_code = 0
        if options.verbose: print time.asctime()
        if options.verbose: print 'TOTAL TIME IN MINUTES:',
        if options.verbose: print (time.time() - start_time) / 60.0
        sys.exit(exit_code)
    except KeyboardInterrupt, e: # Ctrl-C
        raise e
    except SystemExit, e: # sys.exit()
        raise e
    except Exception, e:
        print 'ERROR, UNEXPECTED EXCEPTION'
        print str(e)
        traceback.print_exc()
        os._exit(1)