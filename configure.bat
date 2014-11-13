@echo off
rem
rem Set up compiler to use.
rem
rem Presently implements:
rem
rem IP Pascal, named "ip_pascal"
rem
rem GPC Pascal, named "GPC" (or "gpc")
rem

if not "%1"=="" goto paramok
echo *** Error: Missing parameter
goto stop
:paramok

if not "%1"=="ip_pascal" goto chkgpc
rem
rem Set up for IP Pascal
rem
cp ip_pascal\p5.bat      bin\p5.bat
cp ip_pascal\compile.bat bin\compile.bat
cp ip_pascal\run.bat     bin\run.bat

cp ip_pascal\p5          bin\p5
cp ip_pascal\compile     bin\compile
cp ip_pascal\run         bin\run

cp ip_pascal/Makefile    .

cp ip_pascal\standard_tests/iso7185pat.cmp standard_tests
cp ip_pascal\standard_tests/iso7185pats.cmp standard_tests

rem
rem IP Pascal does not care about line endings, but returning to DOS mode
rem line endings normalizes the files for SVN checkin.
rem
rem doseol

echo Compiler set to IP Pascal
goto stop
:chkgpc

if "%1"=="gpc" goto dogpc
if not "%1"=="GPC" goto nonefound
:dogpc
rem
rem Set up for GPC Pascal
rem
cp gpc\p5.bat      bin\p5.bat
cp gpc\compile.bat bin\compile.bat
cp gpc\run.bat     bin\run.bat

cp gpc\p5          bin\p5
cp gpc\compile     bin\compile
cp gpc\run         bin\run

cp gpc/Makefile    .

cp gpc/standard_tests/iso7185pat.cmp standard_tests
cp gpc/standard_tests/iso7185pats.cmp standard_tests

rem
rem GPC needs Unix line endings in both the Unix and cygwin
rem versions.
rem
rem doseol

echo Compiler set to GPC Pascal
goto stop

rem
rem No compiler name found!
rem
:nonefound
echo *** Compiler name does not match currently implemented
echo *** compilers.
echo.
echo IP Pascal  - use "ip_pascal"
echo GPC Pascal - use "GPC"
echo.
rem
rem Terminate script
rem
:stop
