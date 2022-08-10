% case (Cons (Val1, _Y, _X) of 
%   | nodes [Cons (h, _Y), _X] -> Cons (Val2, nodes [_Y], _X)
%   | otherwise -> Error

case {nu _Z1. (Cons (_Z1, _Y, _X), Val1 (_Z1))} of 
  {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])}
      -> { nu _U1. nu _U2. (Cons (_U1, _U2, _X), Val2 (_U1), nodes [_Y, _U2]) }
  | otherwise -> { Error }
