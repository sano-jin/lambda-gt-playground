%  dlist4.lgt

%  case Cons (1, _Y, _X) of
%    | dlist [Cons (h, _Y), _X] -> dlist [_Y, _X]
%    | otherwise -> Error

let dlist[_Y, _X] = {Log} {nu _Z1 _Z2 _Z3 _Z4. (
    nu _X1. (Cons (_X1, _Z1, _X),  1 (_X1)),
    nu _X1. (Cons (_X1, _Z2, _Z1), 2 (_X1)),
    nu _X1. (Cons (_X1, _Z3, _Z2), 3 (_X1)),
    nu _X1. (Cons (_X1, _Z4, _Z3), 4 (_X1)),
    nu _X1. (Cons (_X1, _Y,  _Z4), 5 (_X1))
    )}
in
let pop[_X] = {(\ dlist[_Y, _X]. 
  case {dlist[_Y, _X]} of
    {nu _W1 _W2. (dlist [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])} -> { dlist [_Y, _X] } 
    | otherwise -> { dlist[_Y, _X] })(_X)}
in
  {pop[_X]} {dlist[_Y, _X]}



%  --->
%  {nu _L0. (1 (_L0), Cons (_L0, _Y, _X))}
