% a.lgt
% A graph with an nullary atom `A`.

case {_L >< _X, nu _N. (Leaf (_N, _X, _R), Zero (_N))} of
   {_L >< _X, nu _N. (Leaf (_N, _L, _R), Zero (_N))} -> {Matched}
 | otherwise -> {Failed}
% --->
% {A ()}
