{

PRT test 1721: For dispose(p,k l ,...,k, ), it is an error unless the variable
               had been created using the form new(p,c l ,...,c,,,) and m is
               equal to n.

               ISO 7185 reference: 6.6.5.3

}

program iso7185prt1721(output);

type a = record case b: boolean of

          true:  (c: integer);
          false: (d: char)

       end;
var e: ^a;

begin

   new(e, true);
   dispose(e, false)

end.
