@echo off
rem
rem Compile with P5 using GPC
rem
rem Execute with:
rem
rem p5 <sourcefile> [<inputfile>[<outputfile>]]
rem
rem where <sourcefile> is the name of the source file without
rem extention. The Pascal file is compiled and run.
rem Any compiler errors are output to the screen. Input
rem and output to and from the running program are from
rem the console, but output to the prr file is placed
rem in <sourcefile>.out.
rem
rem The intermediate code is placed in <file>.p5.
rem
rem If <inputfile> and <outputfile> are specified, then these will be
rem placed as input to the "prd" file, and output from the "prr" file.
rem Note that the prd file cannot or should not be reset, since that
rem would cause it to back up to the start of the intermediate code.
rem
if not "%1"=="" goto paramok
echo *** Error: Missing parameter
goto stop
:paramok
if exist "%1.pas" goto fileexists
echo *** Error: Missing %1.pas file
goto stop
:fileexists
if not "%2"=="" goto continue
if exist "%2" goto continue1
echo *** Error: Missing %1 input file
goto stop
:continue
echo.
echo Compiling and running %1
echo.
if not "%2"=="" goto useinputfile
cp %1.pas prd
goto compile
:useinputfile
rem The input file, if it exists, gets put on the end of the intermediate
cat %1.pas %2 prd
:compile
pcom
mv prr %1.p5
cp %1.p5 prd
pint
if not "%2"=="" goto stop
cp %prr %2
:stop
rm prd
rm prr