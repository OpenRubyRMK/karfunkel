REM Encoding: Windows-1252

REM This file is part of OpenRubyRMK. 
REM
REM Copyright © 2010 Hanmac, Kjarrigan, Quintus
REM
REM OpenRubyRMK is free software: you can redistribute it and/or modify
REM it under the terms of the GNU General Public License as published by
REM the Free Software Foundation, either version 3 of the License, or
REM (at your option) any later version.
REM
REM OpenRubyRMK is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
REM GNU General Public License for more details.
REM
REM You should have received a copy of the GNU General Public License
REM along with OpenRubyRMK.  If not, see <http://www.gnu.org/licenses/>.

@echo off
REM ember that CMD only reads the first line of a file if 
REM called as follows
set /p rb= <..\config\interpreter.txt
echo Using "%rb% as the Ruby Interpreter.
REM ember to start OpenRubyRMK now
call %rb% ..\lib\OpenRubyRMK.rb