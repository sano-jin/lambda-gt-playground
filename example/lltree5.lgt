% lltree5.lgt
% map a function on the leaves of an leaf-linked tree.

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
%> {nu _L0 _L1 _L2 _L3 _L4. (M (_L), Node (_L0, _L1, _X), Leaf (_L2, _L, _L3, _L0), 1 (_L2), Leaf (_L4, _L3, _R, _L1), 2 (_L4))}
%> {nu _L0 _L1 _L2 _L3 _L4. (Leaf (_L0, _L, _L1, _L2), M (_L1), 2 (_L3), Node (_L2, _L4, _X), Leaf (_L3, _L1, _R, _L4), 2 (_L0))}
%> {nu _L0 _L1 _L2 _L3 _L4. (Leaf (_L0, _L1, _R, _L2), M (_R), 2 (_L3), Leaf (_L3, _L, _L1, _L4), Node (_L4, _L2, _X), 3 (_L0))}
%{nu _L0 _L1 _L2 _L3 _L4. (2 (_L0), 3 (_L1), Leaf (_L1, _L2, _R, _L3), Leaf (_L0, _L, _L2, _L4), Node (_L4, _L3, _X))}
