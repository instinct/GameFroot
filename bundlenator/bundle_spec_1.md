# Gamefroot IAP Bundle Specification #

Version 1.0
By Sam Win-Mason

## Folder structure ##

	[Top_Level_Folder] (named after product_id/bundle id)

		* [backgrounds folder]
		* [characters folder]
		* [levels folder]
		* [music folder]
		* [sfx folder]
		* [thumbs folder]
		* [tiles folder]
		* [weapons folder]
		* games.json
		* metadata.json
		* store_image.png (An image to identifiy the pack in the app)
		* store_image-hd.png (An image to identifiy the pack in the app)
		* gamepack_feature.png (A larger featured image for a featured banner (optional))
		* gamepack_feature-hd.png (A larger featured image for a featured banner (optional))
		* screenshot_1.png (Optional)

### Backgrounds folder ###

In-game background files are stored here.

### Character folder ###

Spritesheets for both enemies and the player are stored here.

### Levels folder ###

The JSON map/level files are stored here.

### Music folder ###

Background game music mp3 files are stored here.

### SFX folder ###

Sound effect files are stored here.

### Thumbs folder ###

Individual game thumbnails that appear in the UIList view of a bundle's games are
stored here.

### Tiles folder ###

Spritesheets for a level's tiles are stored here.

### Weapons folder ###

Spritesheets for custom weapons are stored here

### games.json file ###

A JSON file of games that are in the the bundle. Note that there
may be assets for more levels than are listed here if there are multi-level
games. All games in this JSON file that are flagged as published will show up in the app game list view.
The format of the JSON file is identical to the JSON returned by calling the API URL ?gamemakers_api=1&type=get_all_levels&category=foo

### metadata.json file ###

A JSON file with metadata about this bundle. It consists of a single object. Its key value pairs are:

* "size" - The number of games in this bundle (value as int)
* "release_date" - The release date of the bundle (used for subscription checking etc) (value as string in format "dd-mm-yyyy")
* "product_id" - The bundle id, should match the apple iap id for this bundle. (value as string in reverse domain format "com.gamefroot.bundleddmmyyyy")
* "name" - The name of the bundle as it would appear in the Gamefroot bundle store (value as string "Awesome April Ninja Bundle")
* "description" - Some descriptive text about the bundle and it's contents, will appear in the Gamefroot bundle store. (value as string "This is an amazing bundle 
that contains games about ninjas, buy it now!")

### store_image.png file ###

This file defines the thumbnail image for the bundle as it appears in the Gamefroot bundle store in the app. The Gamefroot app will
look for a file with exactly this name in the bundle so no config files are necessary. Dimensions of the image are dependent on implementation details.

### store_image-hd.png file ###

Same as the the store_image.png file but double the resolution for retina displays (Used by Cocos2d automatically). 

### gamepack_feature.png file ###

This is a image larger than the store_image.png file and is used as a featured banner for the Gamefroot bundle store as a whole. 
Used if this bundle is flagged as featured. The Gamefroot app will look for a file with exactly this name in the bundle so no config files are necessary. 
Dimensions of the image are dependent on implementation details. 

### gamepack_feature-hd.png file ###

Same as the the gamepack_feature.png file but double the resolution for retina displays (Used by Cocos2d automatically). 

### screenshot_1.png file ###

This is a screenshot of one of the games in the bundle, used for promotion on the bundle details screen of the Gamefroot bundle store. 
Dimensions of the image are dependent on implementation details. There can be multiple screenshot files where each file must be named above
and numbered sequentially (i.e screenshot_1.png, screenshot_2.png, screenshot_3.png etc). The Gamefroot app will look for files named after this format
to include as screenshots so no config file is needed.


### screenshot_1-hd.png file ###

Retina versions of the above screenshot files (Used by Cocos2d automatically)

