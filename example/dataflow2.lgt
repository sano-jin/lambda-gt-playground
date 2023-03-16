%  dataflow2.lgt
%  Embedding a dataflow langauge.

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

%  --->
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7. (M (_L0, _In), N2 (_L1, _In, _L2), N3 (_L3, _L2, _L4, _L5), N2 (_L6, _L5, _L2), N2 (_L7, _L4, _Out), <fun> (_L1), <fun> (_L3), <fun> (_L6), <fun> (_L7), 5 (_L0))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9. (N2 (_L0, _In, _L1), M (_L2, _L1), <fun> (_L0), T2 (_L3, _L4, _L2), 1 (_L4), 5 (_L3), <fun> (_L5), <fun> (_L6), <fun> (_L7), N3 (_L5, _L1, _L8, _L9), N2 (_L6, _L9, _L1), N2 (_L7, _L8, _Out))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9. (N3 (_L0, _L1, _L2, _L3), M (_L4, _L3), <fun> (_L0), 1 (_L5), 5 (_L6), T2 (_L6, _L5, _L4), <fun> (_L7), <fun> (_L8), <fun> (_L9), N2 (_L7, _In, _L1), N2 (_L8, _L3, _L1), N2 (_L9, _L2, _Out))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9. (N2 (_L0, _L1, _L2), M (_L3, _L2), <fun> (_L0), T2 (_L4, _L5, _L3), 4 (_L4), 5 (_L5), <fun> (_L6), <fun> (_L7), <fun> (_L8), N3 (_L6, _L2, _L9, _L1), N2 (_L7, _In, _L2), N2 (_L8, _L9, _Out))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9. (N3 (_L0, _L1, _L2, _L3), M (_L4, _L3), <fun> (_L0), 4 (_L5), 5 (_L6), T2 (_L5, _L6, _L4), <fun> (_L7), <fun> (_L8), <fun> (_L9), N2 (_L7, _L3, _L1), N2 (_L8, _In, _L1), N2 (_L9, _L2, _Out))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9. (N2 (_L0, _L1, _L2), M (_L3, _L2), <fun> (_L0), T2 (_L4, _L5, _L3), 3 (_L4), 20 (_L5), <fun> (_L6), <fun> (_L7), <fun> (_L8), N3 (_L6, _L2, _L9, _L1), N2 (_L7, _In, _L2), N2 (_L8, _L9, _Out))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9. (N3 (_L0, _L1, _L2, _L3), M (_L4, _L3), <fun> (_L0), 3 (_L5), 20 (_L6), T2 (_L5, _L6, _L4), <fun> (_L7), <fun> (_L8), <fun> (_L9), N2 (_L7, _L3, _L1), N2 (_L8, _In, _L1), N2 (_L9, _L2, _Out))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9. (N2 (_L0, _L1, _L2), M (_L3, _L2), <fun> (_L0), T2 (_L4, _L5, _L3), 2 (_L4), 60 (_L5), <fun> (_L6), <fun> (_L7), <fun> (_L8), N3 (_L6, _L2, _L9, _L1), N2 (_L7, _In, _L2), N2 (_L8, _L9, _Out))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9. (N3 (_L0, _L1, _L2, _L3), M (_L4, _L3), <fun> (_L0), 2 (_L5), 60 (_L6), T2 (_L5, _L6, _L4), <fun> (_L7), <fun> (_L8), <fun> (_L9), N2 (_L7, _L3, _L1), N2 (_L8, _In, _L1), N2 (_L9, _L2, _Out))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9. (N2 (_L0, _L1, _L2), M (_L3, _L2), <fun> (_L0), T2 (_L4, _L5, _L3), 1 (_L4), 120 (_L5), <fun> (_L6), <fun> (_L7), <fun> (_L8), N3 (_L6, _L2, _L9, _L1), N2 (_L7, _In, _L2), N2 (_L8, _L9, _Out))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9. (N3 (_L0, _L1, _L2, _L3), M (_L4, _L3), <fun> (_L0), 1 (_L5), 120 (_L6), T2 (_L5, _L6, _L4), <fun> (_L7), <fun> (_L8), <fun> (_L9), N2 (_L7, _L3, _L1), N2 (_L8, _In, _L1), N2 (_L9, _L2, _Out))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9. (N2 (_L0, _L1, _L2), M (_L3, _L2), <fun> (_L0), T2 (_L4, _L5, _L3), 0 (_L4), 120 (_L5), <fun> (_L6), <fun> (_L7), <fun> (_L8), N3 (_L6, _L2, _L9, _L1), N2 (_L7, _In, _L2), N2 (_L8, _L9, _Out))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7 _L8 _L9. (N3 (_L0, _L1, _L2, _L3), M (_L4, _L2), <fun> (_L0), 0 (_L5), 120 (_L6), T2 (_L5, _L6, _L4), <fun> (_L7), <fun> (_L8), <fun> (_L9), N2 (_L7, _L3, _L1), N2 (_L8, _In, _L1), N2 (_L9, _L2, _Out))}
%  > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6 _L7. (N2 (_L0, _L1, _Out), M (_L2, _Out), <fun> (_L0), 120 (_L2), <fun> (_L3), <fun> (_L4), <fun> (_L5), N2 (_L3, _L6, _L7), N3 (_L4, _L7, _L1, _L6), N2 (_L5, _In, _L7))}
%  {120 (_Z)}
