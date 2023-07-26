% lltree2.lgt
% Failure: map leaves of a leaf-linked tree but unsuccessful.

let f[_X] = {<\x[_X]. {nu _X1. nu _X2. (Succ (_X1, _X), x [_X1])}>(_X)} in

let map[_X] =
  {<\f[_X].{<\x[_L, _R, _X].
  let rec helper[_X] x2[_L, _R, _X, _M] =
    case {Log} {x2[_L, _R, _X, _M]} of
      {nu _L2. nu _R2. nu _X2. nu _X3. (
        y [_L, _R, _X, _M, _R2, _X2],
        Leaf (_X3, _M, _R2, _X2),
        z [_X3]
      )} ->
        let z2[_X] = {f[_X]} {z[_X]} in
        {helper[_X]}
        {nu _L2. nu _R2. nu _X2. nu _X3. nu _X4. (
          y [_L, _R, _X, _L2, _R2, _X2],
          Leaf (_X3, _L2, _R2, _X2),
          z2 [_X3],
          _M >< _R2
        )}
    | otherwise -> case {x2[_L, _R, _X, _M]} of
      { y[_L, _R, _X], _M >< _R } -> { y[_L, _R, _X] }
    | otherwise -> {Error, x2[_L, _R, _X, _M]}
  in {helper [_X]} {x[_L, _R, _X], _M >< _L}
  >(_X)}>(_X)} in

{map[_X]}
{f [_X]}
{
nu _X1. nu _X2. nu _X3. nu _X4. nu _X5. (
  Node (_X1, _X2, _X),
  Leaf (_X4 ,_L, _X3, _X1),
  Zero (_X4),
  Leaf (_X5, _X3, _R, _X2),
  Zero (_X5)
)
}
    

% --->
% > {nu _L0. nu _L1. nu _L2. nu _L3. nu _L4. (_M >< _L, Node (_L0, _L1, _X), Leaf (_L2, _L, _L3, _L0), Zero (_L2), Leaf (_L4, _L3, _R, _L1), Zero (_L4))}
% {nu _L0. nu _L1. nu _L2. nu _L3. nu _L4. (Error (), _M >< _L, Node (_L0, _L1, _X), Leaf (_L2, _L, _L3, _L0), Zero (_L2), Leaf (_L4, _L3, _R, _L1), Zero (_L4))}
