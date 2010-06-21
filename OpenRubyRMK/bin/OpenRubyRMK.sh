#!/bin/bash
#Please don't symlink this file! It uses relative paths!
#If you want a shorthand, create an X starter! 

#Read the Ruby interpreter from the config file. 
#Since the file has Windows newlines CR + LF, 
#we have to strip the CR off before executing the command. 
RB=`head --lines=1 ../config/interpreter.txt | tr -d '\r'`
#Test if the command is valid
if !($RB -v > /dev/null) then
	echo "Invalid startup commmand '$RB'." >&2
	exit 1
fi
echo "Using $RB"
echo "Version is: "
$RB -v
#Now start OpenRubyRMK
$RB ../lib/OpenRubyRMK.rb
