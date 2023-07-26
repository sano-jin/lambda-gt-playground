%  Rotate a difference list (push an element to front from back. length 5).

%  Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, _Y)))), _X)
let dlist[_Y, _X] = {Log} {nu _Z1 _Z2 _Z3 _Z4. (
    nu _X1. (Cons (_X1, _Z1, _X),  1 (_X1)),
    nu _X1. (Cons (_X1, _Z2, _Z1), 2 (_X1)),
    nu _X1. (Cons (_X1, _Z3, _Z2), 3 (_X1)),
    nu _X1. (Cons (_X1, _Z4, _Z3), 4 (_X1)),
    nu _X1. (Cons (_X1, _Y,  _Z4), 5 (_X1))
    )}
in

%  case Cons (1, _Y, _X) of
%    | dlist [Cons (h, _Y), _X] -> Cons (h, dlist [_Y])
%    | otherwise -> Error
let rotate[_X] = {(\dlist[_Y, _X]. 
  case {dlist[_Y, _X]} of
    {nu _W1 _W2. (dlist [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])} 
        -> {nu _W1 _W2. (Cons (_W1, _W2, _X), h [_W1], dlist [_Y, _W2])} 
    | otherwise -> { dlist[_Y, _X] })(_X)}
in

  {rotate[_X]} {dlist[_Y, _X]})

% %  Apply `rotate` once.
% let dlist[_Y, _X] = {Log} (
%       {rotate[_X]} {dlist[_Y, _X]}) in
% 
% %  Loop `f` to the `dlist`.
% let rec loop[_X] f[_X] dlist[_Y, _X] = 
%   let dlist'[_Y, _X] = {Log} ({f[_X]} {dlist[_Y, _X]}) in
%   {loop[_X]} {f[_X]} {dlist'[_Y, _X]}
% in
% 
% {loop[_X]} {rotate[_X]} {dlist[_Y, _X]}
