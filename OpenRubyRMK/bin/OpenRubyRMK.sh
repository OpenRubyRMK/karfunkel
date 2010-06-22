#!/bin/bash
#Encoding: UTF-8

#This file is part of OpenRubyRMK. 
#
#Copyright © 2010 Hanmac, Kjarrigan, Quintus
#
#OpenRubyRMK is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#OpenRubyRMK is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with OpenRubyRMK.  If not, see <http://www.gnu.org/licenses/>.


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
