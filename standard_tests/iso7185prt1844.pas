{

PRT test 1843: Variable reference to packed variable

}

program iso7185prt1843;

var r: packed record
          i: integer;
          b: boolean
       end;

procedure a(var b: boolean);

begin

end;

begin

   a(r.b)

end.