{

PRT test 1806: Threats to FOR statement index.

    Threat in same scope block, VAR parameter.
    ISO 7185 6.8.3.9

}

program iso7185prt1806(output);

var i: integer;

procedure a(var i: integer);

begin

   i := 1

end;

procedure b;

begin

   a(i)

end;

begin

   for i := 1 to 10 do begin

      write(i:1, ' ')

   end

end.