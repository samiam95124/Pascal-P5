{

PRT test 1843: Variable reference to tagfield.

}

program iso7185prt1843;

var r: record
          case b: boolean of
             true:  ();
             false: ();
       end;

procedure a(var b: boolean);

begin

end;

begin

   a(r.b)

end.