module Examples exposing (..)

{-| This example demonstrates a force directed graph with zoom and drag
functionality.

@delay 5
@category Advanced

-}

-- Constants


dlist =
    """% dlist.lgt
%  Pop the last element of a difference list (length 1).

%  > case Cons (Val, _Y, _X) of
%  >   | nodes [Cons (h, _Y), _X] -> nodes [_Y, _X]
%  >   | otherwise -> Error

case {nu _Z1. (Cons (_Z1, _Y, _X), 1 (_Z1))} of
  {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])} -> { nodes [_Y, _X] } 
  | otherwise -> { Error }

% --->
% {_Y >< _X}"""


dlist2 =
    """% dlist2.lgt
% Append two difference lists.

% (λ x[Y, X] y[Y, X]. x[y[Y], X]) (_X) 
%   Cons (1, Cons (2, Cons (3, Y, X), X), X)
%   Cons (4, Cons (5, Y, X), X)

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
  {(\\ x[_Y, _X]. {(\\ y[_Y, _X]. {nu _Z. (x[_Z, _X], y[_Y, _Z])})(_X)})(_X)}
in
{f[_X]} {dlist1[_Y, _X]} {dlist2[_Y, _X]}
"""


dlist3 =
    """% dlist3.lgt
%  Rotate a difference list (push an element to front from back. length 5).

% Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, _Y)))), _X)
let dlist[_Y, _X] = {Log} {nu _Z1 _Z2 _Z3 _Z4. (
    nu _X1. (Cons (_X1, _Z1, _X),  1 (_X1)),
    nu _X1. (Cons (_X1, _Z2, _Z1), 2 (_X1)),
    nu _X1. (Cons (_X1, _Z3, _Z2), 3 (_X1)),
    nu _X1. (Cons (_X1, _Z4, _Z3), 4 (_X1)),
    nu _X1. (Cons (_X1, _Y,  _Z4), 5 (_X1))
    )}
in

% case Cons (1, _Y, _X) of
%   | dlist [Cons (h, _Y), _X] -> Cons (h, dlist [_Y])
%   | otherwise -> Error
let rotate[_X] = {(\\dlist[_Y, _X]. 
  case {dlist[_Y, _X]} of
    {nu _W1 _W2. (dlist [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])} 
        -> {nu _W1 _W2. (Cons (_W1, _W2, _X), h [_W1], dlist [_Y, _W2])} 
    | otherwise -> { dlist[_Y, _X] })(_X)}
in

%  Apply `rotate` once.
let dlist[_Y, _X] = {Log} (
      {rotate[_X]} {dlist[_Y, _X]}) in

%  Loop `f` to the `dlist`.
let rec loop[_X] f[_X] dlist[_Y, _X] = 
  let dlist'[_Y, _X] = {Log} ({f[_X]} {dlist[_Y, _X]}) in
  {loop[_X]} {f[_X]} {dlist'[_Y, _X]}
in

{loop[_X]} {rotate[_X]} {dlist[_Y, _X]}
"""


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
% Pop the last element of a difference list (length 5).

%  Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, _Y)))), _X)
let dlist[_Y, _X] = {Log} {nu _Z1 _Z2 _Z3 _Z4. (
    nu _X1. (Cons (_X1, _Z1, _X),  1 (_X1)),
    nu _X1. (Cons (_X1, _Z2, _Z1), 2 (_X1)),
    nu _X1. (Cons (_X1, _Z3, _Z2), 3 (_X1)),
    nu _X1. (Cons (_X1, _Z4, _Z3), 4 (_X1)),
    nu _X1. (Cons (_X1, _Y,  _Z4), 5 (_X1))
    )}
in

%  case dlist[_Y, _X] of
%    | dlist[Cons (h, _Y), _X] -> dlist[_Y, _X]
%    | otherwise -> dlist[_Y, _X]
let pop[_X] = {(\\dlist[_Y, _X]. 
  case {dlist[_Y, _X]} of
    {nu _W1 _W2. (dlist [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])} -> { dlist [_Y, _X] } 
    | otherwise -> { dlist[_Y, _X] })(_X)}
in

%  Apply `rotate` once.
let dlist[_Y, _X] = {Log} (
      {pop[_X]} {dlist[_Y, _X]}) in

%  Loop applying `f` to the `dlist`.
let rec loop[_X] f[_X] dlist[_Y, _X] = 
  let dlist'[_Y, _X] = {Log} ({f[_X]} {dlist[_Y, _X]}) in
  {loop[_X]} {f[_X]} {dlist'[_Y, _X]}
in

{loop[_X]} {pop[_X]} {dlist[_Y, _X]}
"""


dlist5 =
    """
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
    Cons (_Z1,   _Z2, _X),   1 (_Z1), 
    Cons (_Z3,   _Z4, _Z2),  2 (_Z3),
    Cons (_Z5,   _Z6, _Z4),  3 (_Z5),
    Cons (_Z7,   _Z8, _Z6),  4 (_Z7),
    Cons (_Z9,  _Z10, _Z8),  5 (_Z9),
    Cons (_Z11, _Z12, _Z10), 6 (_Z11),
    Cons (_Z13, _Y, _Z12),   7 (_Z13)
  )}
  """


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
"""


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
"""


lltree5 =
    """% Map a function to the leaves of a leaf-linked tree.

let succ[_X] x[_X] = {x[_X]} + {1(_X)} in

let map[_X] f[_X] x[_L, _R, _X] =
  let rec helper[_X] x2[_L, _R, _X] =
    case {Log} {x2[_L, _R, _X]} of
      {nu _L2 _R2 _X2 _X3. (
        y [_L, _R, _X, _L2, _R2, _X2],
        M (_L2)), Leaf (_X3, _L2, _R2, _X2), z [_X3]}
      -> let z2[_X] = {f[_X]} {z[_X]} in
        {helper[_X]}
        {nu _L2 _R2 _X2 _X3 _X4. (
          y [_L, _R, _X, _L2, _R2, _X2],
          Leaf (_X3, _L2, _R2, _X2), z2 [_X3], M (_R2))}
    | otherwise -> case {x2[_L, _R, _X]} of
      { y[_L, _R, _X], M (_R) } -> { y[_L, _R, _X] }
    | otherwise -> {Error, x2[_L, _R, _X]}
  in {helper [_X]} {x[_L, _R, _X], M (_L)}
in

{map[_X]} {succ[_X]} ({Log} {
  nu _X1 _X2 _X10. (Node (_X1, _X2, _X),
    nu _X3 _X4 _X7. (Node (_X3, _X4, _X1),
      nu _X8. (Leaf (_X8 ,_L, _X7, _X3), 1 (_X8)),
      nu _X9. (Leaf (_X9, _X7, _X10, _X4), 2 (_X9))
   ),
   nu _X5 _X6 _X11. (Node (_X5, _X6, _X2),
      nu _X12. (Leaf (_X12 ,_X10, _X11, _X5), 3 (_X12)),
      nu _X13. (Leaf (_X13, _X11, _R, _X6), 4 (_X13))
))})
"""


dataflow2 =
    """% Embedding a dataflow langauge.

% let f1 n = (n,1)
let f1[_Z] n[_Z] = {nu _N1 _N2.(T2(_N1,_N2,_Z),n[_N1],1(_N2))} in

% let pred1 (i,_) = i = 0
let pred1[_Z] v[_Z] = case {v[_Z]} of
  {nu _I _K.(T2(_I,_K,_Z),i[_I],k[_K])} -> {i[_Z]} = {0(_Z)}
  | otherwise -> {Error1} in

% let f2 (i,k) = (i - 1,k * i)
let f2[_Z] v[_Z] = case {v[_Z]} of
  {nu _I _K.(T2(_I,_K,_Z),i[_I],k[_K])} ->
    let i'[_Z] = {i[_Z]} - {1(_Z)} in
    let k'[_Z] = {k[_Z]} * {i[_Z]} in
    {nu _I _K.(T2(_I,_K,_Z),i'[_I],k'[_K])}
  | otherwise -> {Error2} in

% let f3 (_,k) = k
let f3[_Z] v[_Z] = case {v[_Z]} of
  {nu _I _K.(T2(_I,_K,_Z),i[_I],k[_K])} -> {k[_Z]}
  | otherwise -> {Error3} in

% The dataflow to caliculate the factorial of an input number.
let dataflow[_In,_Out] = {nu _X1 _X2 _X3 _F1 _F2 _P.(
  N2(_F1,_In,_X1),f1[_F1],
  N3(_P,_X1,_X3,_X2),pred1[_P],
  N2(_F2,_X2,_X1),f2[_F2],
  N2(_F3,_X3,_Out),f3[_F3]
)} in

% The evaluator
let rec proceed[_Z] g[_In,_Out] =
  case {Log} {g[_In,_Out]} of
    {nu _X _Y _F _V.(N2(_F,_X,_Y),f[_F],
       M(_V,_X),v[_V],rest[_X,_Y,_In,_Out])} ->
     let v'[_Z] = {f[_Z]} {v[_Z]} in
     {proceed[_Z]} {nu _X _Y _F _V.(N2(_F,_X,_Y),f[_F],
                      M(_V,_Y),v'[_V],rest[_X,_Y,_In,_Out])}
  | otherwise -> case {g[_In,_Out]} of
    {nu _X _Y1 _Y2 _P _V.(N3(_P,_X,_Y1,_Y2),pred[_P],
       M(_V,_X),v[_V],rest[_X,_Y1,_Y2,_In,_Out])} ->
     {proceed[_Z]} (case {pred[_Z]} {v[_Z]} of
        {True(_Z)} -> {nu _X _Y1 _Y2 _P _V.(N3(_P,_X,_Y1,_Y2),pred[_P],
                         M(_V,_Y1),v[_V],rest[_X,_Y1,_Y2,_In,_Out])}
      | otherwise  -> {nu _X _Y1 _Y2 _P _V.(N3(_P,_X,_Y1,_Y2),pred[_P],
                         M(_V,_Y2),v[_V],rest[_X,_Y1,_Y2,_In,_Out])})
  | otherwise -> case {g[_In,_Out]} of
    {nu _V.(M(_V,_Out),v[_V],rest[_In,_Out])} -> {v[_Z]}
  | otherwise -> {Error4} in

% Initialise with a marker
let run[_Z] v[_Z] g[_In,_Out] = 
  {proceed[_Z]} {nu _V.(g[_In,_Out],M(_V,_In),v[_V])} in

% The main code
{run[_Z]} {5(_Z)} {dataflow[_In,_Out]} % 5!
% {run[_Z]} {3(_Z)} {nu _X.(dataflow[_In,_X],dataflow[_X,_Out])} % (3!)!

"""
