@echo off
REM ember that CMD only reads the first line of a file if 
REM called as follows
set /p rb= <..\config\interpreter.txt
echo Using "%rb% as the Ruby Interpreter.
REM ember to start OpenRubyRMK now
call %rb% ..\lib\OpenRubyRMK.rb