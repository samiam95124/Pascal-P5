@echo off
rem
rem Compile with P5 using GPC
rem
rem Execute with:
rem
rem p5 <file>
rem
rem where <file> is the name of the source file without
rem extention. The Pascal file is compiled and run.
rem Any compiler errors are output to the screen. Input
rem and output to and from the running program are from
rem the console, but output to the prr file is placed
rem in <file>.out.
rem The intermediate code is placed in <file>.p5.
rem
if not "%1"=="" goto paramok
echo *** Error: Missing parameter
goto stop
:paramok
if exist "%1.pas" goto fileexists
echo *** Error: Missing %1.pas file
goto stop
:fileexists
echo.
echo Compiling and running %1
echo.
pcom < %1.pas
del %1.p5 > temp
copy prr %1.p5 > temp
del prr
copy %1.p5 prd > temp
pint
del temp
