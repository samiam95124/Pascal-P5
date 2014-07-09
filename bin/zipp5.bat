@echo off
rem
rem Make Zip archive of this directory
rem
del p5.zip
rem
rem Documentation
rem
zip p5.zip readme.txt
zip p5.zip todo.txt
zip p5.zip news.txt
rem
rem P5 and its binaries
rem
zip p5.zip pcom.pas
zip p5.zip pcom.exe
zip p5.zip pcom
zip p5.zip pint.pas
zip p5.zip pint.exe
zip p5.zip pint
rem
rem Scripts to run compiles, tests, etc.
rem
zip p5.zip configure.bat
zip p5.zip configure
zip p5.zip p5.bat
zip p5.zip p5
zip p5.zip compile.bat
zip p5.zip compile
zip p5.zip run.bat
zip p5.zip run
zip p5.zip testprog.bat
zip p5.zip testprog
zip p5.zip cpcom.bat
zip p5.zip cpcom
zip p5.zip cpint.bat
zip p5.zip cpint
zip p5.zip cpcoms.bat
zip p5.zip cpcoms
zip p5.zip cpints.bat
zip p5.zip cpints
zip p5.zip regress.bat
zip p5.zip regress
zip p5.zip diffnole.bat
zip p5.zip diffnole
zip p5.zip fixeol.bat
zip p5.zip fixeol
zip p5.zip build.bat
zip p5.zip build
zip p5.zip unixeol
rem
rem Misc from top level
rem
zip p5.zip pintm.inp
zip p5.zip flip.c
zip p5.zip make_flip
rem
rem Sample/test programs
rem
zip p5.zip sample_programs\hello.pas
zip p5.zip sample_programs\hello.inp
zip p5.zip sample_programs\hello.cmp
zip p5.zip sample_programs\roman.pas
zip p5.zip sample_programs\roman.inp
zip p5.zip sample_programs\roman.cmp
zip p5.zip sample_programs\match.pas
zip p5.zip sample_programs\match.inp
zip p5.zip sample_programs\match.cmp
zip p5.zip sample_programs\startrek.pas
zip p5.zip sample_programs\startrek.inp
zip p5.zip sample_programs\startrek.cmp
zip p5.zip sample_programs\basics.pas
zip p5.zip sample_programs\basics.inp
zip p5.zip sample_programs\basics.cmp
zip p5.zip sample_programs\match.bas
zip p5.zip standard_tests\iso7185pat.pas
zip p5.zip standard_tests\iso7185pat.inp
zip p5.zip standard_tests\iso7185pat.cmp
zip p5.zip standard_tests\iso7185pats.cmp
rem
rem GPC specific versions of the scripts
rem
zip p5.zip gpc\compile.bat
zip p5.zip gpc\compile
zip p5.zip gpc\cpcom.bat
zip p5.zip gpc\cpcom
zip p5.zip gpc\cpint.bat
zip p5.zip gpc\cpint
zip p5.zip gpc\p5.bat
zip p5.zip gpc\p5
zip p5.zip gpc\run.bat
zip p5.zip gpc\run
rem
rem IP Pascal specific versions of the scripts
rem
zip p5.zip ip_pascal\compile.bat
zip p5.zip ip_pascal\compile
zip p5.zip ip_pascal\cpcom.bat
zip p5.zip ip_pascal\cpcom
zip p5.zip ip_pascal\cpint.bat
zip p5.zip ip_pascal\cpint
zip p5.zip ip_pascal\p5.bat
zip p5.zip ip_pascal\p5
zip p5.zip ip_pascal\run.bat
zip p5.zip ip_pascal\run
rem
rem GPC binaries
rem
zip p5.zip gpc\linux_X86\pcom
zip p5.zip gpc\linux_X86\pint
zip p5.zip gpc\windows_X86\pcom.exe
zip p5.zip gpc\windows_X86\pint.exe
rem
rem GPC binaries
rem
zip p5.zip ip_pascal\windows_X86\pcom.exe
zip p5.zip ip_pascal\windows_X86\pint.exe
rem
rem IP Pascal PAT compare files
rem
zip p5.zip ip_pascal\standard_tests\iso7185pat.cmp
zip p5.zip ip_pascal\standard_tests\iso7185pats.cmp
rem
rem GPC PAT compare files
rem
zip p5.zip gpc\standard_tests\iso7185pat.cmp
zip p5.zip gpc\standard_tests\iso7185pats.cmp
rem
rem Documentation
rem
zip p5.zip iso7185.html
zip p5.zip iso7185.pdf
zip p5.zip iso7185rules.html
zip p5.zip The_Programming_Language_Pascal_1973.pdf
