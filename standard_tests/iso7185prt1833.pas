{

PRT test 1832: Goto/label issues

    Intraprocedure Goto nested block.

}

program iso7185prt1832(output);

label 1;

var i: integer;

procedure abort;

begin

   goto 1

end;

begin

   abort;
   for i := 1 to 10 do begin

      1: writeln(i)

   end

end.