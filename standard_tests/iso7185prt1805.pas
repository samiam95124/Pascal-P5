{

PRT test 1805: Threats to FOR statement index.

    Threat in same scope block, assignment.
    ISO 7185 6.8.3.9

}

program iso7185prt1805(output);

var i: integer;

procedure a;

begin

   i := 1

end;

begin

   for i := 1 to 10 do begin

      write(i:1, ' ')

   end

end.