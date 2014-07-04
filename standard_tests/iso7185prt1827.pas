{

PRT test 1827: Files of files

    File in substructure.

}

program iso7185prt1827;

type r = record

            i: integer;
            f: text

         end;

var f: file of r;

begin

end.