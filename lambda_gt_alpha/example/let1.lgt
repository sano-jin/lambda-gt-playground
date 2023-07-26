% let1.lgt
% Testing let binding.

let x[_Y, _X] = 
  {nu _Z. (Cons (_Z, _Y, _X), Val (_Z))}
in
  {nu _Z1. nu _Z2. (x[_Z1, _X], Cons (_Z1, _Y, _Z2), Val (_Z))}

% --->
% {nu _L0. nu _L1. nu _L2. (Cons (_L0, _Y, _L1), Val (_Z), Cons (_L2, _L0, _X), Val (_L2))}
