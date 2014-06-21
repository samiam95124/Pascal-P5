{

PRT test 1722: For dispose(p,k l ,...,k, ), it is an error if the variants in 
               the variable identified by the pointer value of p are different
               from those specified by the case-constants k l ,...,k,,,,.

               ISO 7185 reference: 6.6.5.3

               This test case needs further research. In test #19, and the
               6.6.5.3 clause clearly disallows initializing or changing the
               variants in a way inconsistent with the origin of the variable
               in new. The test case describes ending up in a dispose where
               either the current active variants do not match the dispose
               declaration, or where the dispose tagfields do not match that
               of the originating new. Thus, this test case would seem to be
               impossible given the other, existing error requirements and 
               thus would fail before reaching the failing dispose.

}

program iso7185prt1722;

begin

end.
