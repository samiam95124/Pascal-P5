@echo off
rem
rem Difference without line endings
rem
rem Same as diff, but ignores the DOS/Unix line ending differences.
rem

if "%1"=="" (

    echo *** Error: Missing parameter 1
    echo "*** s/b \"diffnole \<file1> \<file2>\""
    exit /b 1

)

if not exist "%1" (

    echo *** Error: Missing %1 file
    exit /b 1

)

if "%2"=="" (

    echo *** Error: Missing parameter 2
    echo "*** s/b \"diffnole \<file1> \<file2>\""
    exit /b 1

)

if not exist "%2" (

    echo *** Error: Missing %2 file
    exit /b 1

)

copy %1 %1.tmp > tmp3
copy %2 %2.tmp > tmp3
flip -u -b %1.tmp
flip -u -b %2.tmp
diff %1.tmp %2.tmp
rm -f %1.tmp
rm -f %2.tmp
rm -f tmp3
