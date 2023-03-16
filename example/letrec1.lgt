% letrec1.lgt
% Pop all the elements from back of a difference list.

let rec f[_X] nodes[_Y, _X] = 
  case { Log } {nodes[_Y, _X]} of
    {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])} -> {f [_X]} { nodes [_Y, _X] } 
    | otherwise -> { Empty }
in
  {f[_X]} 
    {nu _Z1. nu _Z2. nu _Z3. (Cons (_Z1, _Z2, _X), Val1 (_Z1), Cons (_Z3, _Y, _Z2), Val2 (_Z3))}

% --->
%> {nu _L0 _L1 _L2. (Cons (_L0, _L1, _X), Val1 (_L0), Cons (_L2, _Y, _L1), Val2 (_L2))}
%> {nu _L0. (Val1 (_L0), Cons (_L0, _Y, _X))}
%> {_Y >< _X}
%{Empty}
