{

PRT test 1822: Invalid type substitutions

    Use of subrange for VAR reference.

}

program iso7185prt1821(input);

var c: 1..10;

procedure a(var b: integer);

begin

end;

begin

   a(c)

end.