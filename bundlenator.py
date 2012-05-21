#!/usr/bin/env python

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

    bundlenator [-h] [-v,--verbose] [--version] category_name endpoint_url bundle_output_path [existing bundle paths...]

DESCRIPTION
	
	usage: bundlenator [-h] [-v,--verbose] [--version] category_name endpoint_url bundle_output_path [existing bundle paths...]

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
import hashlib

# Some global config strings, change as required

GET_LEVELS_API_STRING = '?gamemakers_api=1&type=get_all_levels&category='
GET_TILES_API_STRING = '?gamemakers_api=1&type=get_game_animations&id='
GET_MAP_API_STRING = '?gamemakers_api=1&type=json&map_id='
GET_BACKGROUND_URL = '/wp-content/plugins/game_data/backgrounds/user/'
GET_CHARACTER_URL = '/wp-content/characters/'
BUNDLE_FOLDER_NAME = 'iap_bundle'

DEFAULT_BUNDLE_INFO = str('{ "product_id":0, "name":"My Amazing Game Bundle", "release_date":"", "size":"script will fill in"}')


def loadGameData():

	global gamedata

	if options.verbose: sys.stdout.write( "retrieving game list for category " + args[0] + "...")

	# get game data
	requestString = args[1] + GET_LEVELS_API_STRING + args[0]
	gameDataFH = urllib.urlopen(requestString)
	gamedata = json.load(gameDataFH)
	if options.verbose: sys.stdout.write("[done]\n")
	try:
		open(args[2] + BUNDLE_FOLDER_NAME + "/games.json", 'w').write(json.dumps(gamedata))
	except Exception, e:
		raise
	else:
		pass
	finally:
		pass
	


def loadAsset(dirName, urlString, filename=None):
	localFilePath = ''
	bundleRelativePath = ''

	if(filename):
		localFilePath = args[2] + BUNDLE_FOLDER_NAME + "/" + dirName + "/" + filename
		bundleRelativePath = BUNDLE_FOLDER_NAME + "/" + dirName + "/" + filename
	else:
		localFilePath = args[2] + BUNDLE_FOLDER_NAME + "/" + dirName + "/" + os.path.split(urlString)[1]
		bundleRelativePath = BUNDLE_FOLDER_NAME + "/" + dirName + "/" + os.path.split(urlString)[1]
	
	if(not os.path.exists(localFilePath)):

		# Check in existing supplied bindle paths to see if the assets exist
		assetExists = False
		for bPath in existingBundles:
			if os.path.exists(bpath + bundleRelativePath) :
				assetExists = True

		if not assetExists :
			try:
				if options.verbose: sys.stdout.write('\tdownloading asset ' + urlString + '...') 
				inetFH = urllib.urlopen(urlString)
				localFH = open(localFilePath, 'w')
				localFH.write(inetFH.read())
				if options.verbose: sys.stdout.write('[done] ') 
			except Exception, e:
				raise
			else:
				pass
			finally:
				if options.verbose: sys.stdout.write('[saved]\n')



def loadGameAssets():
	global levelsDownloaded

	sys.stdout.write("retrieving game assets...\n")

	levelsDownloaded = list()

	# for each level, load the assets
	for level in gamedata:
		sys.stdout.write ("\nretrieving assets for '" + level['title'] + "'...\n")
		# Thumb
		if options.verbose: sys.stdout.write("\tdownloading thumb...")
		loadAsset('thumbs',level['background'])

		if options.verbose: sys.stdout.write( "\tdownloading map data\n")
		if level['id'] not in levelsDownloaded:
			loadLevelAssets(level['id'])

		

def loadLevelAssets(mapId):
	localFilePath = args[2] + BUNDLE_FOLDER_NAME + "/levels/" + `mapId` + ".map"
	if(not os.path.exists(localFilePath)):
		try:
			inetFH = urllib.urlopen(args[1] + GET_MAP_API_STRING + `mapId`)
			levelData = json.load(inetFH)
			localFH = open(localFilePath, 'w')
			localFH.write(json.dumps(levelData))

			# Load custom bg music
			if options.verbose: sys.stdout.write('\n\t[Background music]\n')
			for music in levelData['sprites']['background_music']:
				loadAsset('music', music['url'])
				

			# Load backgrounds
			if options.verbose: sys.stdout.write('\n\t[Backgrounds]\n')
			loadAsset('backgrounds', (args[1] + GET_BACKGROUND_URL + levelData['meta']['background']['image']))

			if options.verbose: sys.stdout.write('\n\t[Spritesheets]\n')
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
			loadAsset('characters', args[1] + GET_CHARACTER_URL + sheetName)	

			# Load character
			if (int(levelData['map']['player']['num']) < 100):
				sheetName = "player_" + `levelData['map']['player']['num']` + ".png"
			else:
				sheetName = "character" + `levelData['map']['player']['num']` + ".png"

			# print args[1] + GET_CHARACTER_URL + sheetName
			loadAsset('characters', args[1] + GET_CHARACTER_URL + sheetName)

			# Load custom SFX
			if options.verbose: sys.stdout.write('\n\t[SFX]\n')
			for sfx in levelData['sprites']['sounds']:
				loadAsset('sfx', sfx['url']);
			

			# Load custom weapon spritesheets
			if options.verbose: sys.stdout.write('\n\t[Custom Weapon spritesheets]\n')
			for weapon in levelData['sprites']['weapons']:
				loadAsset('weapons', weapon['file'])
			

			# Load custom tilesets
			if options.verbose: sys.stdout.write('\n\t[Tiles]\n')
			# print args[1] + GET_TILES_API_STRING + `mapId`
			loadAsset('tiles', args[1] + GET_TILES_API_STRING + `mapId`, `mapId` + '.png')

			if options.verbose: sys.stdout.write('\n\t[Checking for additional levels]\n')

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
					if options.verbose: sys.stdout.write('\nLoading connected level...\n')
					loadLevelAssets(int(l))

		except Exception, e:
			sys.stdout.write("An error as occured downloading one or more assets [Failwhale]")
			raise
		else:
			pass
		finally:
			pass

			

def createDirectoryStructure():
	if(os.path.exists(args[2])):
		# Create directories
		sys.stdout.write("creating bundle directory structure...\n")
		try:
			os.chdir(args[2])
			os.mkdir(BUNDLE_FOLDER_NAME)
			os.chdir(BUNDLE_FOLDER_NAME)
			os.mkdir("thumbs")
			os.mkdir("backgrounds")
			os.mkdir("characters")
			os.mkdir("tiles")
			os.mkdir("sfx")
			os.mkdir("music")
			os.mkdir("weapons")
			os.mkdir("levels")

		except Exception, e:
			sys.stdout.write("There was an error creating bundle directories at the specifed path [Failwhale]")
		
	else :
		sys.stdout.write('specified path does not exist [Failwhale]')


def writePackageReceipt():
	packageJSON = json.loads(DEFAULT_BUNDLE_INFO)
	
	# Add size
	packageJSON['size'] = len(gamedata)
	try:
		metadataFilename = args[2] + BUNDLE_FOLDER_NAME + "/metadata.json"
		metaDataFH = open(metadataFilename, 'w')
		metaDataFH.write(json.dumps(packageJSON))
	except Exception, e:
		sys.stdout.write("unable to wite package metadata [Failwhale]")
		raise
	else:
		pass
	finally:
		pass


def main ():

	global options, args, existingBundles

	sys.stdout.write('Bundlenator - The Gamefroot IAP packaging tool\n\n')

	# print 'Getting list of games from server ... ';
	
	# Create folder structure
	if(len(args) >= 3):
		
		if(len(args) > 3):
			existingBundles = args[4:]
		else:
			existingBundles = []
		
		createDirectoryStructure()
		loadGameData()
		loadGameAssets()
		writePackageReceipt()

	else:
		sys.stdout.write( "USAGE: bundlenator [-h] [-v,--verbose] [--version] category_name endpoint_url bundle_output_path [existing bundle paths...]")




if __name__ == '__main__':
    try:
        start_time = time.time()
        parser = optparse.OptionParser(
                formatter=optparse.TitledHelpFormatter(),
                usage=globals()['__doc__'],
                version='1.0 - newbaby!')
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