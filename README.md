iPhotoShotwell
==============

Script to import iPhoto library to shotwell

Context
----

My girlfriend macbook died.
I have the backup of the iPhoto Library folder and a computer with Ubuntu linux. Time for importing data…

After googling a bit, I found no clue for importing from iPhoto to shotwell, just a ticket open in the yorba redmine.

I started to drag and drop folders but i wasn't convinced it was the better way to do it with 7 years of pictures. (Time spent today on developping showed it might have be).

How does it works
----

I found in the iPhoto Library folder an xml file named AlbumData.xml.

The script parses this file to lazily fill the shotwell DB.
The idea is to parse everything from the xml file but insert only what is stricly required by shotwell in its DB.

For the moment it does not move files to another folder. Should not be hard to add.

Was just test on my backup and my Shotwell version (0.12.3 shipped with ubuntu 12.04)

Requirements
----

it's like a PoC so it's written in Ruby. I coded it using ruby 1.8.7, I don't know if it will work on ruby 1.9
it requires nokogiri, sqlite3 and image\_size gems and mplayer.

How to use it
----

just exec
	ruby iPhotoShotwell.rb pathToAlbumData.xml pathToShotwellDB.db

It's advised to make a backup of the shotwell configuration database before running it

Once it's over launch shotwell wich will work a lot to recreate thumbnails, and fill the database.

Performance
----

Poor! As expected the sqlite3 ruby driver behave slowly and i made nothing to optimize speed.
For example the import of around 8500 photos and 50 videos last 25 minutes on my laptop (core i5). The reconstruction of database by shotwell was about 30 minutes.

Known issues
----

* Does not import hidden photos (there are not in the XML)
* Uses Original pictures not the one modified in iPhoto

Todo
----

* Add option for moving files
* Have a report of what files remind
* Add an option to choose Modified file rather than Original one
