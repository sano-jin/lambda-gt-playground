module Examples exposing (..)

{-| This example demonstrates a force directed graph with zoom and drag
functionality.

@delay 5
@category Advanced

-}

-- Constants


dlist =
    """% dlist.lgt
% Pop the last element of a difference list (length 1).

% case Cons (Val, _Y, _X) of
%   | nodes [Cons (h, _Y), _X] -> nodes [_Y, _X]
%   | otherwise -> Error

case {nu _Z1. (Cons (_Z1, _Y, _X), 1 (_Z1))} of
  {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])} -> { nodes [_Y, _X] } 
  | otherwise -> { Error }

% --->
% {_Y >< _X}"""


dlist2 =
    """% dlist2.lgt
% Append two difference lists.

% (\\x[Y, X] y[Y, X].x[y[Y], X]) () 
%   Cons (1, Y, X)
%   Cons (1, Y, X)

{<\\ x[_Y, _X]. {<\\ y[_Y, _X]. {nu _Z. (x[_Z, _X], y[_Y, _Z])}>}>}
  {Cons (_X1, _Y, _X), 1 (_X1)}
  {Cons (_X1, _Y, _X), 2 (_X1)}

% --->
% {nu _L0. nu _L1. nu _L2. (Cons (_L1, _L0, _X), 1 (_L1), Cons (_L2, _Y, _L0), 2 (_L2))}"""


dlist3 =
    """% dlist3.lgt
% Rotate a difference list (push an element to front from back).

% case (Cons (Val1, _Y, _X) of 
%   | nodes [Cons (h, _Y), _X] -> Cons (h, nodes [_Y], _X)
%   | otherwise -> Error

case {nu _L0. nu _L1. nu _L2. (Cons (_L1, _L0, _X), 1 (_L1), Cons (_L2, _Y, _L0), 2 (_L2))} of 
  {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])}
      -> { nu _U1. nu _U2. (Cons (_U1, _U2, _X), h [_U1], nodes [_Y, _U2]) }
  | otherwise -> { Error }

% --->
% {nu _L0. nu _L1. nu _L2. (Cons (_L1, _L0, _X), 2 (_L1), Cons (_L2, _Y, _L0), 1 (_L2))}"""


dlist3b =
    """% dlist3.lgt
% Rotate a difference list (push an element to front from back, length 1).

% case (Cons (Val1, _Y, _X) of 
%   | nodes [Cons (h, _Y), _X] -> Cons (h, nodes [_Y], _X)
%   | otherwise -> Error

case {nu _L0. (Cons (_L0, _Y, _X), 1 (_L0))} of 
  {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])}
      -> { nu _U1. nu _U2. (Cons (_U1, _U2, _X), h [_U1], nodes [_Y, _U2]) }
  | otherwise -> { Error }

% --->
% {nu _L0. (Cons (_L0, _Y, _X), 1 (_L0))}"""


dlist4 =
    """% dlist4.lgt
% Pop the last element of a difference list (length 2).

% case Cons (1, _Y, _X) of
%   | nodes [Cons (h, _Y), _X] -> nodes [_Y, _X]
%   | otherwise -> Error

let nodes[_Y, _X] = 
  {nu _Z1. nu _Z2. nu _Z3. (Cons (_Z1, _Z2, _X), 1 (_Z1), Cons (_Z3, _Y, _Z2), 2 (_Z3))}
in
  case {nodes[_Y, _X]} of
    {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])} -> { nodes [_Y, _X] } 
    | otherwise -> { Empty }

% --->
% {nu _L0. (1 (_L0), Cons (_L0, _Y, _X))}"""


dlist5 =
    """% case Cons (Val, _Y, _X) of
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
    Cons (_Z1,   _Z2, _X),   1 (_Z1), 
    Cons (_Z3,   _Z4, _Z2),  2 (_Z3),
    Cons (_Z5,   _Z6, _Z4),  3 (_Z5),
    Cons (_Z7,   _Z8, _Z6),  4 (_Z7),
    Cons (_Z9,  _Z10, _Z8),  5 (_Z9),
    Cons (_Z11, _Z12, _Z10), 6 (_Z11),
    Cons (_Z13, _Y, _Z12),   7 (_Z13)
  )}"""


letrec1 =
    """% letrec1.lgt
% Pop all the elements from back of a difference list.

% case Cons (Val, _Y, _X) of
%   | nodes [Cons (h, _Y), _X] -> nodes [_Y, _X]
%   | otherwise -> Error

let rec f[_X] nodes[_Y, _X] = 
  case { Log } {nodes[_Y, _X]} of
    {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])} -> {f [_X]} { nodes [_Y, _X] } 
    | otherwise -> { Empty }
in
  {f[_X]} 
    {nu _Z1. nu _Z2. nu _Z3. (Cons (_Z1, _Z2, _X), 1 (_Z1), Cons (_Z3, _Y, _Z2), 2 (_Z3))}

% --->
% > {nu _L0. nu _L1. nu _L2. (Cons (_L0, _L1, _X), 1 (_L0), Cons (_L2, _Y, _L1), 2 (_L2))}
% > {nu _L0. (1 (_L0), Cons (_L0, _Y, _X))}
% > {_Y >< _X}
% {Empty ()}"""


lltree3 =
    """% lltree3.lgt
% Map a function to the leaves of a leaf-linked tree.

let succ[_X] x[_X] = {x[_X]} + {1(_X)} in

let map[_X] f[_X] x[_L, _R, _X] = 
  let rec helper[_X] x2[_L, _R, _X] =
    case {Log} {x2[_L, _R, _X]} of 
      {nu _L2 _R2 _X2 _X3. (
        y [_L, _R, _X, _L2, _R2, _X2], 
        Leaf (_X3, _L2, _R2, _X2), 
        z [_X3],
        M (_L2)
      )} -> 
        let z2[_X] = {f[_X]} {z[_X]} in
        {helper[_X]}
        {nu _L2 _R2 _X2 _X3 _X4. (
          y [_L, _R, _X, _L2, _R2, _X2], 
          Leaf (_X3, _L2, _R2, _X2), 
          z2 [_X3],
          M (_R2)
        )}
    | otherwise -> case {x2[_L, _R, _X]} of
      { y[_L, _R, _X], M (_R) } -> { y[_L, _R, _X] }
    | otherwise -> {Error, x2[_L, _R, _X]}
  in {helper [_X]} {x[_L, _R, _X], M (_L)}
in

{map[_X]} 
{succ[_X]}
{nu _X1 _X2 _X3 _X4 _X5. (
  Node (_X1, _X2, _X), 
  Leaf (_X4 ,_L, _X3, _X1),
  1 (_X4),
  Leaf (_X5, _X3, _R, _X2),
  2 (_X5)
)}

    

% --->
% > {nu _L0 _L1 _L2 _L3 _L4. (M (_L), Node (_L0, _L1, _X), Leaf (_L2, _L, _L3, _L0), Zero (_L2), Leaf (_L4, _L3, _R, _L1), Zero (_L4))}
% > {nu _L0 _L1 _L2 _L3 _L4 _L5. (Leaf (_L0, _L, _L1, _L2), M (_L1), Zero (_L3), Node (_L2, _L4, _X), Leaf (_L3, _L1, _R, _L4), Succ (_L5, _L0), Zero (_L5))}
% > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6. (Leaf (_L0, _L1, _R, _L2), M (_R), Zero (_L3), Succ (_L3, _L4), Leaf (_L4, _L, _L1, _L5), Node (_L5, _L2, _X), Succ (_L6, _L0), Zero (_L6))}
% {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6. (Zero (_L0), Zero (_L1), Succ (_L0, _L2), Succ (_L1, _L3), Leaf (_L3, _L4, _R, _L5), Leaf (_L2, _L, _L4, _L6), Node (_L6, _L5, _X))}"""


lltree5 =
    """% Map a function to the leaves of a leaf-linked tree.
let succ[_X] x[_X] = {x[_X]} + {1(_X)} in
let map[_X] f[_X] x[_L, _R, _X] =
  let rec helper[_X] x2[_L, _R, _X] =
    case {Log} {x2[_L, _R, _X]} of
      {nu _L2 _R2 _X2 _X3. (
        y [_L, _R, _X, _L2, _R2, _X2],
        Leaf (_X3, _L2, _R2, _X2),
        z [_X3],
        M (_L2)
      )} ->
        let z2[_X] = {f[_X]} {z[_X]} in
        {helper[_X]}
        {nu _L2 _R2 _X2 _X3 _X4. (
          y [_L, _R, _X, _L2, _R2, _X2],
          Leaf (_X3, _L2, _R2, _X2),
          z2 [_X3],
          M (_R2)
        )}
    | otherwise -> case {x2[_L, _R, _X]} of
      { y[_L, _R, _X], M (_R) } -> { y[_L, _R, _X] }
    | otherwise -> {Error, x2[_L, _R, _X]}
  in {helper [_X]} {x[_L, _R, _X], M (_L)}
in
{map[_X]}
{succ[_X]}
{nu _X1 _X2 _X3 _X4 _X5 _X6 _X7 _X8 _X9 _X10 _X11 _X12 _X13. (
  Node (_X1, _X2, _X),

  Node (_X3, _X4, _X1),
  Leaf (_X8 ,_L, _X7, _X3),
  1 (_X8),
  Leaf (_X9, _X7, _X10, _X4),
  2 (_X9),
  
  Node (_X5, _X6, _X2),
  Leaf (_X12 ,_X10, _X11, _X5),
  3 (_X12),
  Leaf (_X13, _X11, _R, _X6),
  4 (_X13)
)}"""
