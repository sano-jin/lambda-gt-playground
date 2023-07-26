%  lltree2.lgt
%  Map a function on the leaves of an leaf-linked tree.

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

    

%  --->
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9 _L10 _L11 _L12. (Node (_L0, _L1, _X), Node (_L3, _L4, _L0), Leaf (_L6, _L, _L5, _L3), 1 (_L6), Leaf (_L7, _L5, _L2, _L4), 2 (_L7), Node (_L8, _L9, _L1), Leaf (_L11, _L2, _L10, _L8), 3 (_L11), Leaf (_L12, _L10, _R, _L9), 4 (_L12))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9 _L10 _L11 _L12. (M (_L), Node (_L0, _L1, _X), Node (_L2, _L3, _L0), Leaf (_L4, _L, _L5, _L2), 1 (_L4), Leaf (_L6, _L5, _L7, _L3), 2 (_L6), Node (_L8, _L9, _L1), Leaf (_L10, _L7, _L11, _L8), 3 (_L10), Leaf (_L12, _L11, _R, _L9), 4 (_L12))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9 _L10 _L11 _L12. (Leaf (_L0, _L, _L1, _L2), M (_L1), 3 (_L3), 2 (_L4), Node (_L5, _L6, _L7), Leaf (_L3, _L8, _L9, _L5), 4 (_L10), Node (_L11, _L7, _X), Node (_L2, _L12, _L11), Leaf (_L4, _L1, _L8, _L12), Leaf (_L10, _L9, _R, _L6), 2 (_L0))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9 _L10 _L11 _L12. (Leaf (_L0, _L1, _L2, _L3), M (_L2), 3 (_L4), Node (_L5, _L6, _L7), 4 (_L8), 2 (_L9), Leaf (_L9, _L, _L1, _L10), Leaf (_L4, _L2, _L11, _L5), Node (_L12, _L7, _X), Node (_L10, _L3, _L12), Leaf (_L8, _L11, _R, _L6), 3 (_L0))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9 _L10 _L11 _L12. (Leaf (_L0, _L1, _L2, _L3), M (_L2), 4 (_L4), 2 (_L5), Node (_L6, _L7, _L8), 3 (_L9), Leaf (_L9, _L10, _L1, _L7), Node (_L3, _L11, _L12), Leaf (_L5, _L, _L10, _L6), Node (_L8, _L12, _X), Leaf (_L4, _L2, _R, _L11), 4 (_L0))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9 _L10 _L11 _L12. (Leaf (_L0, _L1, _R, _L2), M (_R), 3 (_L3), 2 (_L4), Node (_L5, _L6, _L7), Leaf (_L3, _L8, _L9, _L6), 4 (_L10), Leaf (_L10, _L9, _L1, _L11), Node (_L11, _L2, _L12), Leaf (_L4, _L, _L8, _L5), Node (_L7, _L12, _X), 5 (_L0))}
%  {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9 _L10 _L11 _L12. (3 (_L0), 4 (_L1), 2 (_L2), Node (_L3, _L4, _L5), Leaf (_L0, _L6, _L7, _L4), Leaf (_L1, _L7, _L8, _L9), Node (_L9, _L10, _L11), 5 (_L12), Leaf (_L12, _L8, _R, _L10), Leaf (_L2, _L, _L6, _L3), Node (_L5, _L11, _X))}
