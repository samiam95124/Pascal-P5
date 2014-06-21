rem
rem Fix line ending on bash scripts
rem
echo.
echo Fixing the line endings on Unix files
echo.
flip -u build
flip -u clean
flip -u compile
flip -u configure
flip -u cpcom
flip -u cpcoms
flip -u cpint
flip -u cpints
flip -u diffnole
flip -u doseol
flip -u fixeol
flip -u make_flip
flip -u p5
flip -u regress
flip -u run
flip -u testpascals
flip -u testprog
flip -u unixeol
flip -u zipp5
flip -u gpc/compile
flip -u gpc/cpcom
flip -u gpc/cpint
flip -u gpc/p5
flip -u gpc/run
flip -u ip_pascal/compile
flip -u ip_pascal/cpcom
flip -u ip_pascal/cpint
flip -u ip_pascal/p5
flip -u ip_pascal/run
flip -u make_flip
echo.
echo Fixing the line enddings on DOS/Windows files
echo.
flip -m build.bat
flip -m clean.bat
flip -m compile.bat
flip -m configure.bat
flip -m cpcom.bat
flip -m cpcoms.bat
flip -m cpint.bat
flip -m cpints.bat
flip -m diffnole.bat
flip -m doseol.bat
rem flip -m     fixeol.bat
flip -m make_flip.bat
flip -m p5.bat
flip -m prtprt.bat
flip -m regress.bat
flip -m run.bat
flip -m testpascals.bat
flip -m testprog.bat
flip -m unixeol.bat
flip -m zipp5.bat
flip -m gpc/compile.bat
flip -m gpc/cpcom.bat
flip -m gpc/cpint.bat
flip -m gpc/p5.bat
flip -m gpc/run.bat
flip -m ip_pascal/compile.bat
flip -m ip_pascal/cpcom.bat
flip -m ip_pascal/cpint.bat
flip -m ip_pascal/p5.bat
flip -m ip_pascal/run.bat
