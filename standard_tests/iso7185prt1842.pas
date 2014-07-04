{

PRT test 1842: Use of text procedure with non-text

    Use readln with integer file.

}

program iso7185prt1842(output);

var f: file of integer;
    i: integer;

begin

   rewrite(f);
   write(f, 1);
   reset(f);
   readln(f, i)

end.