% lltree3.lgt
% map a function on the leaves of an leaf-linked tree.

let f[_X] = {<\x[_X]. {nu _X1 _X2. (Succ (_X1, _X), x [_X1])}>(_X)} in

let map[_X] = 
  {<[_X].{<\x[_L, _R, _X].
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
  >(_X)}>(_X)} in

{map[_X]} 
{f[_X]}
{nu _X1 _X2 _X3 _X4 _X5. (
  Node (_X1, _X2, _X), 
  Leaf (_X4 ,_L, _X3, _X1),
  Zero (_X4),
  Leaf (_X5, _X3, _R, _X2),
  Zero (_X5)
)}

    

% --->
%Fatal error: exception Failure("At offset 134: syntax error.")
