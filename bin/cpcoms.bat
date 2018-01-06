@echo off
rem
rem Script to run a pcom self compile
rem
rem First, change elide patterns to remove prr file statements.
rem The modified file goes in pcomm.pas (pcom modified).
rem
sed -e 's/{elide}/{/g' -e 's/{noelide}/}/g' source\pcom.pas > pcomm.pas
rem
rem Compile pcom to intermediate code using its binary version.
rem
echo Compiling pcom to intermediate code
call compile pcomm
type pcomm.err
rem
rem Now run that code on the interpreter and have it compile itself
rem to intermediate again.
rem
echo Running pcom to compile itself
cat pcomm.p5 pcomm.pas > tmp.p5
mv pcomm.p5 pcomm.p5.org
cp tmp.p5 pcomm.p5
echo.> pcomm.inp
call run pcomm
type pcomm.lst
rem
rem Now we have the original intermediate from the binary version
rem of pcom, and the intermediate generated by the interpreted
rem pcom. Compare them for equality. Put the result in pcomm.dif.
rem
echo Comparing the intermediate code for the runs
call diffnole pcomm.p5.org pcomm.out > pcomm.dif
rem
rem Show the file, so if the length is zero, it compared ok.
rem
echo Resulting diff file length should be zero for pass
dir pcomm.dif
