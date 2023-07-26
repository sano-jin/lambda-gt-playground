%  dlist.lgt
%  Pop the last element of a difference list (length 1).

case {nu _Z1. (Cons (_Z1, _Y, _X), Val (_Z1))} of
  {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])} -> { nodes [_Y, _X] } 
  | otherwise -> { Error }

%  --->
%  {_Y >< _X}
