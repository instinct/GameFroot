#!/usr/bin/env python

'''
	1. 
	- create folder structure
	- Download list of games from website

	2.

	For each game in list:
		- * Check to see if not downloaded already
		* If not then:
			- download json of level
			- download custom spritesheets
			- download custom backgrounds
			- download custom sfx
			- download custom music
			- download custom tilesheets
			- download custom weapon spritesheets
			- check for jump to level robot, if found for each level:
				load level as above. (recurse)
	
	3. 	
	write plist

	* Add default bundle to check for existing files

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

# Some global config strings, change as required

GET_LEVELS_API_STRING = '?gamemakers_api=1&type=get_all_levels&category='
GET_TILES_API_STRING = '?gamemakers_api=1&type=get_game_animations&id='
GET_MAP_API_STRING = '?gamemakers_api=1&type=json&map_id='
GET_BACKGROUND_URL = '/wp-content/plugins/game_data/backgrounds/user/'
GET_CHARACTER_URL = '/wp-content/characters/'

DEFAULT_BUNDLE_INFO = str('{ "product_id":0, "" }')


def loadGameData():

	global gamedata

	if options.verbose: print "retrieving game list for category " + args[0] + "..."

	# get game data
	requestString = args[1] + GET_LEVELS_API_STRING + args[0]
	gameDataFH = urllib.urlopen(requestString)
	gamedata = json.load(gameDataFH)



def loadAsset(dirName, urlString):
	localFilePath = args[2] + "iap_bundle/" + dirName + "/" + os.path.split(urlString)[1]
	if(not os.path.exists(localFilePath)):
		try:
			inetFH = urllib.urlopen(urlString)
			if options.verbose: print '[done]'
			localFH = open(localFilePath, 'w')
			localFH.write(inetFH.read())
		except Exception, e:
			raise
		else:
			pass
		finally:
			if options.verbose: print '[saved]'



def loadGameAssets():
	global levelsDownloaded

	print "retrieving game assets..."

	levelsDownloaded = list()

	# for each level, load the assets
	for level in gamedata:
		print "retrieving assets for '" + level['title'] + "'..."
		# Thumb
		if options.verbose: print "		downloading thumb..."
		# loadAsset('thumbs',level['background'])

		if options.verbose: print "		downloading map data"
		if level['id'] not in levelsDownloaded:
			loadLevelAssets(level['id'])


		

def loadLevelAssets(mapId):
	localFilePath = args[2] + "iap_bundle/levels/" + `mapId` + ".map"
	if(not os.path.exists(localFilePath)):
		try:
			inetFH = urllib.urlopen(args[1] + GET_MAP_API_STRING + `mapId`)
			levelData = json.load(inetFH)
			# localFH = open(localFilePath, 'w')
			# localFH.write(inetFH.read())

			# Load custom bg music
			for music in levelData['sprites']['background_music']:
				# loadAsset('music', music['url'])
				pass

			# Load backgrounds
			# loadAsset('backgrounds', (args[1] + GET_BACKGROUND_URL + levelData['meta']['background']['image']))

			# Load custom spritesheets
			# Load enemies

			sheetName = ''

			for enemy in levelData['map']['characters']:
				enemyNum = int(enemy['num'])
				if(enemyNum < 100):
					sheetName = 'enemy_sheet' + `enemyNum` + '.png'
				else:
					sheetName = 'enemy' + `enemyNum` + '.png'
		
			# print args[1] + GET_CHARACTER_URL + sheetName
			# loadAsset('characters', args[1] + GET_CHARACTER_URL + sheetName)	

			# Load character
			if (int(levelData['map']['player']['num']) < 100):
				sheetName = "player_" + `levelData['map']['player']['num']` + ".png"
			else:
				sheetName = "character" + `levelData['map']['player']['num']` + ".png"

			# print args[1] + GET_CHARACTER_URL + sheetName
			# loadAsset('characters', args[1] + GET_CHARACTER_URL + sheetName)

			# Load custom SFX
			for sfx in levelData['sprites']['sounds']:
				# loadAsset('sfx', sfx['url']);
				pass

			# Load custom weapon spritesheets
			for weapon in levelData['sprites']['weapons']:
				# loadAsset('weapons', weapon['file'])
				pass

			# Load custom tilesets
			# print args[1] + GET_TILES_API_STRING + `mapId`
			# loadAsset('tiles', args[1] + GET_TILES_API_STRING + mapId)

			levelsDownloaded.append(mapId)
			connectedLevels = list()

			# Get list of level jump robot scripts
			for script in levelData['sprites']['robots']:
				for behaviour in script['script']['behavior']:
					for command in behaviour['commands']:
						if command['action'] == 'gotoLevel':
							connectedLevels.append(int(command['level']))
			

			# If not already downloaded, recursively load attached levels
			for l in connectedLevels:
				if l not in levelsDownloaded:
					loadLevelAssets(int(l))

		except Exception, e:
			print "An error as occured downloading one or more assets [Failwhale]"
			raise
		else:
			pass
		finally:
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
			os.mkdir("levels")

		except Exception, e:
			print "There was an error creating bundle directories at the specifed path [Failwhale]"
		
	else :
		print 'specified path does not exist [Failwhale]'


def writePackageReceipt():
	pass


def main ():

	global options, args

	print 'Bundlenator - The Gamefroot IAP packaging tool'

	# print 'Getting list of games from server ... ';
	
	# Create folder structure
	if(len(args) == 3):

		# createDirectoryStructure()
		loadGameData()
		loadGameAssets()
		writePackageReceipt()

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