{

PRT test 1820: Backwards pointer association.

    Indicates an error unless a pointer reference uses backwards assocation,
    which is incorrect.
    ISO 7185 6.2.2.9, 6.4.1

}

program iso7185prt1820(output);

type a = integer;

procedure b;

var cp: ^a;
    a:  char;

begin

    new(cp);
    cp^ := 1

end;

begin

   b


end.