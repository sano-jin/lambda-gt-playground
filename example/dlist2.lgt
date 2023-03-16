%  dlist2.lgt
%  Append two difference lists.

{(\x[_Y,_X]. {(\y[_Y,_X]. {nu _Z. (x[_Z,_X], y[_Y,_Z])})})}
  {Cons(_X1,_Y,_X), 1(_X1)}
  {Cons(_X1,_Y,_X), 2(_X1)}

%  --->
%  {nu _L0 _L1 _L2. (Cons (_L1, _L0, _X), 1 (_L1), Cons (_L2, _Y, _L0), 2 (_L2))}
