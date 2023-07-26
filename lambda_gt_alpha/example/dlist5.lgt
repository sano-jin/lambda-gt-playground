
% case Cons (Val, _Y, _X) of
%   | nodes [Cons (h, _Y), _X] -> nodes [_Y, _X]
%   | otherwise -> Error

let rec f[_X] nodes[_Y, _X] =
  case {Log} {nodes[_Y, _X]} of
    {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])} -> {f [_X]} { nodes [_Y, _X] }
    | otherwise -> { Empty }
in
  {f[_X]}
  {nu _Z1. nu _Z2. nu _Z3. nu _Z4. nu _Z5. 
   nu _Z6. nu _Z7. nu _Z8. nu _Z9. nu _Z10.
   nu _Z11. nu _Z12. nu _Z13. (
    Cons (_Z1,   _Z2, _X),  Val1 (_Z1), 
    Cons (_Z3,   _Z4, _Z2), Val2 (_Z3),
    Cons (_Z5,   _Z6, _Z4), Val3 (_Z5),
    Cons (_Z7,   _Z8, _Z6), Val4 (_Z7),
    Cons (_Z9,  _Z10, _Z8), Val5 (_Z9),
    Cons (_Z11, _Z12, _Z10), Val6 (_Z11),
    Cons (_Z13, _Y, _Z12), Val7 (_Z13)
  )}

