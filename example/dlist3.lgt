% dlist3.lgt
% Rotate a difference list (push an element to front from back).

case {nu _Z1. (Cons (_Z1, _Y, _X), Val1 (_Z1))} of 
  {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])}
      -> { nu _U1. nu _U2. (Cons (_U1, _U2, _X), Val2 (_U1), nodes [_Y, _U2]) }
  | otherwise -> { Error }

% --->
%{nu _L0. (Cons (_L0, _Y, _X), Val2 (_L0))}
