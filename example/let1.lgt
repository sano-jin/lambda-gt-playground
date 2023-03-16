%  let1.lgt
%  Testing let binding.

let x[_Y, _X] = 
  {nu _Z. (Cons (_Z, _Y, _X), 1 (_Z))}
in
  {nu _Z1. nu _Z2. (x[_Z1, _X], Cons (_Z1, _Y, _Z2), 2 (_Z))}

%  --->
%  {nu _L0 _L1 _L2. (Cons (_L0, _Y, _L1), 2 (_Z), Cons (_L2, _L0, _X), 1 (_L2))}
