% let2.lgt
% Testing let binding.

let x[_Y, _X] = 
  {nu _Z. (Cons (_Z, _Y, _X), Val1 (_Z))}
in
  {nu _Z1. nu _Z2. nu _Z11. nu _Z12. (x[_Z11, _X], _Z11 >< _Z22, Cons (_Z12, _Y, _Z2), Val2 (_Z))}

% --->
% {nu _L1. nu _L3. nu _L4. (Cons (_L3, _Y, _L1), Val2 (_Z), Cons (_L4, _Z22, _X), Val1 (_L4))}
