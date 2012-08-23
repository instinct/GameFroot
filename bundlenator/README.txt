BUNDLENATOR README
==================

Version 1.0 By Sam Win-Mason
Copyright (C)2012 Instinct Entertainment Limited


Description
-----------

Bundlenator is a command-line tool to package a series of games created with the 
Gamefroot HTML5 gamemaking tools into a suitable asset bundle that can be used as 
an in-app purchase for download to the iOS Gamefroot app.

The command-line tool would be ideally used in conjnction with a GUI for specifiying
additional metadata for the bundle.


Requirements
------------

The Bundlenator script needs to run on a Unix system (i.e MacOSX, Linux) and requires
that the Python 2.x interpreter be installed on the system (this is installled by default on MacOSX)
The script is unlikely to work in Python 3.x. You will also need access to the internet, as the script
fetches the assets remotely via http requests.


Who Would Use This Tool?
------------------------

The Gamefroot iOS developer would use this tool to automate the creation of in-app purchase bundles.


Instructions for Use
--------------------

The tool has the following usage:

bundlenator [-h] [-v,--verbose] [--version] category_name endpoint_url bundle_output_path [existing bundle paths...]

where the arguments are explained below:

-h                           prints some help text
-v or --verbose              prints a more detailed progress report about what is happening
category_name                the Gamefroot Wordpress category name that holds the games to be packaged into the in-app purchase
endpoint_url                 the primary domain that the script will look for assets on, normally should be http://gamefroot.com
                             but could be the staging URL
bundle_output_path           the local directory where the new bundle will be created, the bundle assets will be put in a folder
                             specified by the script constant BUNDLE_FOLDER_NAME. This folder will be created in the directory specified
[existing bundle paths...]   a list of existing bundle paths for the script to check for assets. If the script finds a requested asset in
                             one of these local bundles, it won't be downloaded again into the new bundle. This is a way to reduce the 
                             size of the bundle by having a 'common' bundle of fequently used assets

NOTE!! All directory paths supplied must be absolute paths. 


Things that the Script Won't Do
-------------------------------

* Add the date metadata
* Add the name of the bundle (as it appears in the app)
* Add the bundle feature artwork and list-view artwork
* Add the product id of the bundle, this must match the Apple specified id in iTunes connect.

Although the script doesn't populate those values, it generates the metadata.json file in the
bundle with placeholder values. This could be populated by a front end GUI which could also add
the feature and list-view artwork


Bug Fix requests and Feedback
-----------------------------

Please direct these to:

Sam Win-Mason
sam@albedogames.com




