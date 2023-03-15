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
      case {pred[_Z]} {v[_Z]} of
        {True(_Z)} -> 
          {proceed[_Z]} {nu _X _Y1 _Y2 _P _V.(N3(_P,_X,_Y1,_Y2),pred[_P],
                           M(_V,_Y1),v[_V],rest[_X,_Y1,_Y2,_In,_Out])}
      | otherwise -> 
          {proceed[_Z]} {nu _X _Y1 _Y2 _P _V.(N3(_P,_X,_Y1,_Y2),pred[_P],
                           M(_V,_Y2),v[_V],rest[_X,_Y1,_Y2,_In,_Out])} 
  | otherwise -> case {g[_In,_Out]} of
    {nu _V.(M(_V,_Out),v[_V],rest[_In,_Out])} -> {v[_Z]}
  | otherwise -> {Error4} in

% Initialise with a marker
let run[_Z] v[_Z] g[_In,_Out] = 
  {proceed[_Z]} {nu _V.(g[_In,_Out],M(_V,_In),v[_V])} in

% The main code
{run[_Z]} {5(_Z)} {dataflow[_In,_Out]} % 5!
% {run[_Z]} {3(_Z)} {nu _X.(dataflow[_In,_X],dataflow[_X,_Out])} % (3!)!

