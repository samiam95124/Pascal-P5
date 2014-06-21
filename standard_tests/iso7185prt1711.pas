{

PRT test 1711: It is an error if end-of-file is not true immediately prior to
               any use of put, write, writeln or page.

               ISO 7185 reference: 6.6.5.2

               I don't know how this is possible. A rewrite is required
               to put the file into write mode, and each subsequent write leaves
               eof on.
}

program iso7185prt1711(output);

begin

end.
