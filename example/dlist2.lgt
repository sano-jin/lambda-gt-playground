%  dlist2.lgt
%  Append two difference lists.

let dlist1[_Y, _X] = {Log} {nu _Z1 _Z2. (
    nu _X1. (Cons (_X1, _Z1, _X),  1 (_X1)),
    nu _X1. (Cons (_X1, _Z2, _Z1), 2 (_X1)),
    nu _X1. (Cons (_X1, _Y, _Z2),  3 (_X1))
    )}
in
let dlist2[_Y, _X] = {Log} {nu _Z1. (
    nu _X1. (Cons (_X1, _Z1, _X), 4 (_X1)),
    nu _X1. (Cons (_X1, _Y, _Z1), 5 (_X1))
    )}
in
let f[_X] =
  {(\ x[_Y, _X]. {(\ y[_Y, _X]. {nu _Z. (x[_Z, _X], y[_Y, _Z])})(_X)})(_X)}
in
{f[_X]} {dlist1[_Y, _X]} {dlist2[_Y, _X]}

%  --->
% > {nu _L0 _L1 _L2 _L3 _L4. (Cons (_L2, _L0, _X), 1 (_L2), Cons (_L3, _L1, _L0), 2 (_L3), Cons (_L4, _Y, _L1), 3 (_L4))}
% > {nu _L0 _L1 _L2. (Cons (_L1, _L0, _X), 4 (_L1), Cons (_L2, _Y, _L0), 5 (_L2))}
% {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8. (Cons (_L1, _L2, _X), 1 (_L1), Cons (_L3, _L4, _L2), 2 (_L3), Cons (_L5, _L0, _L4), 3 (_L5), Cons (_L6, _L7, _L0), 4 (_L6), Cons (_L8, _Y, _L7), 5 (_L8))}
