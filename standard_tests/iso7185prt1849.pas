{

PRT test 1844: Variable reference to packed variable

   Passing a packed element as a variable reference.
   ISO 7185 6.6.3.3


}

program iso7185prt1844;

type prec = packed record
               i: integer;
               b: boolean
            end;

var r: record
          i: integer;
          b: boolean;
          r: record
             c: char;
             d: prec
          end
       end;

procedure a(var b: boolean);

begin

end;

begin

   a(r.r.d.b)

end.