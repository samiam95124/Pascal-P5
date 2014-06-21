{

PRT test 1742: When eoln(f) is activated, it is an error if eof(f) is true.

               ISO 7185 reference: 6.6.5.5

}

program iso7185prt1742(output);

var a: text;

begin

   { note the standard describes an empty file as having no lines, and eof 
     true }
   rewrite(a);
   reset(a);
   { As usual, it is possible that this could be completely optimized out }
   if eoln(a) then

end.
