#!/usr/bin/ruby

#Author: Gaëtan Duchaussois
#Licence: WTFPL
#Usage: ruby iPhotoShotwell.rb pathToAlbumData.xml pathToShotwellDB.db

require 'nokogiri'
require "sqlite3"
require 'image_size'

class IphotoLib
	def initialize(file)
		@Albums=Array.new
		@Images=Array.new
		@iPhotoRoot=File.dirname(file)
		f=File.open(file)
		@doc=Nokogiri::XML(f)
		f.close
		@doc.xpath("/plist/dict/key").each do |sect|
			case sect.content
				#when "List of Albums" then parseAlbum(sect.next_sibling.next_sibling)
				when "List of Rolls" then parseAlbum(sect.next_sibling.next_sibling)
				when "Master Image List" then parseImage(sect.next_sibling.next_sibling)
				when "Archive Path" then @origPath=sect.next_sibling.next_sibling.content
			end
		end
	end
	def parseAlbum(list)
		list.xpath("./dict").each do |album|
			hAlbum=xml2Hash(album.children)
			@Albums.push(hAlbum)
		end
	end
	def parseImage(list)
		list.xpath("./dict").each do |album|
			id=album.previous_sibling.previous_sibling.content.to_i
			hAlbum=xml2Hash(album.children)
			@Images[id]=hAlbum
		end
	end
	def xml2Hash(xml)
		ret=Hash.new
		key=nil
		value=nil
		xml.each do |elem|
			case elem.name
				when "key" then key=elem.content
				when "array" then value=keyList2tab(elem.children)
				when "text" then next
				else value=elem.content
			end
			if not key.nil? and not value.nil? then
				ret[key]=value
				key=nil
				value=nil
			end
		end
		return ret
	end
	def keyList2tab(xml)
		ret=Array.new
		xml.each do |elem|
			ret.push(elem.content) if elem.name=="string"
		end
		return ret
	end
	def getAlbum(nom=nil)
		if nom.nil?
			return @Albums
		else
			return @Albums[@Albums.index {|a| a["RollName"] == nom }]
		end
	end
	def getImage(id=nil)
		if id.nil?
			return @Images
		else
			return @Images[id]
		end
	end
	def getCurrPath(imageId,type="Original")
		path=@Images[imageId][type+"Path"]
		path=@Images[imageId]["ImagePath"] if path.nil?
		return path.sub(@origPath,@iPhotoRoot)
	end
end

class ShotwellLib
	def initialize(db)
		@db = SQLite3::Database.new db
		@log= File.open("import.log","w")
	end
	def addEvent(nomEvent)
		@db.execute("insert into EventTable(name) values(:nomEvent)","nomEvent" => nomEvent)
		return @db.last_insert_row_id
	end
	def addVideo(fileName,event=nil)
		vInfo=Hash.new
		cmdline="mplayer -frames 0 -identify '#{fileName}' 2> /dev/null |grep ^ID_"
		lines=IO.popen(cmdline).readlines
		lines.each do |line|
			line.strip!
			tTab=line.split(/=/)
			vInfo[tTab[0]]=tTab[1]
		end
		#p vInfo
		@db.execute("insert into VideoTable(filename,width,height,clip_duration,event_id) values(:fileName,:width,:height,:duration,:event);","fileName"=>fileName,"width"=> vInfo["ID_VIDEO_WIDTH"], "height" => vInfo["ID_VIDEO_HEIGHT"], "event"=> event, "duration"=> vInfo["ID_LENGTH"])
	end
	def addImage(fileName,event=nil)
		puts fileName
		fileName.gsub!("û","û")
		fileName.gsub!("ï","ï")
		fileName.gsub!("É","É")
		fileName.gsub!("é","é")
		@log.puts(fileName)
		f=File.open(fileName)
		is=ImageSize.new(f.read).get_size
		f.close
		width=is[0]
		height=is[1]
		if width.nil? then
			addVideo(fileName,event)
		else
			@db.execute("insert into PhotoTable(filename,width,height,event_id) values(:fileName,:width,:height,:event);","fileName"=>fileName,"width"=> width, "height" => height, "event"=> event)
		end
	end
end

ip=IphotoLib.new(ARGV[0])
sw=ShotwellLib.new(ARGV[1])
#ip.getAlbum.each do |album|
#	p album
#end/
#i5=ip.getImage(5)
#p i5
#sw.addImage(ip.getCurrPath(5,"Original"),9)
#
#ev=ip.getAlbum("strasbourg 12_2004")
#p ev
#eid=sw.addEvent("strasbourg 12_2004")
#ev["KeyList"].each do |img|
#	puts img
#	sw.addImage(ip.getCurrPath(img.to_i,"Original"),eid)
#end

#sw.addVideo("/opt/share/iPhoto Library/Originals/2011/Chile décembre 2011/MVI_1413.MOV",261)

#exit

ip.getAlbum.each do |ev|
	eid=sw.addEvent(ev["RollName"])
	ev["KeyList"].each do |img|
		puts img
		sw.addImage(ip.getCurrPath(img.to_i,"Original"),eid)
	end
end
