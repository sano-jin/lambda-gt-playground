% dlist4.lgt
% Pop the last element of a difference list (length 2).

% case Cons (Val, _Y, _X) of
%   | nodes [Cons (h, _Y), _X] -> nodes [_Y, _X]
%   | otherwise -> Error

let nodes[_Y, _X] = 
  {nu _Z1. nu _Z2. nu _Z3. (Cons (_Z1, _Z2, _X), Val1 (_Z1), Cons (_Z3, _Y, _Z2), Val2 (_Z3))}
in
  case {nodes[_Y, _X]} of
    {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])} -> { nodes [_Y, _X] } 
    | otherwise -> { Empty }

% --->
% {nu _L0. (Val1 (_L0), Cons (_L0, _Y, _X))}
