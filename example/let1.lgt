let x[_Y, _X] = 
  {nu _Z. (Cons (_Z, _Y, _X), Val (_Z))}
in
  {nu _Z1. nu _Z2. (x[_Z1, _X], Cons (_Z1, _Y, _Z2), Val (_Z))}
