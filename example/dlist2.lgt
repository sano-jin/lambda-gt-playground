% dlist2.lgt
% Append two difference lists.

{<\ x[_Y, _X]. {<\ y[_Y, _X]. {nu _Z. (x[_Z, _X], y[_Y, _Z])}>}>}
  {Cons (_X1, _Y, _X), Val1 (_X1)}
  {Cons (_X1, _Y, _X), Val2 (_X1)}

% --->
%Fatal error: exception Failure("At offset 127: syntax error.")
