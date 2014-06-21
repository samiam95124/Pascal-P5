{

PRT test 1708: For a value parameter, it is an error if the actual-parameter
               is an expression of a set-type whose value is not
               assignment-compatible with the type possessed by the
               formal-parameter.

               ISO 7185 reference: 6.6.3.2

}

program iso7185prt1708(output);

var a: set of 1..5;

begin

   a := [3,6]

end.
