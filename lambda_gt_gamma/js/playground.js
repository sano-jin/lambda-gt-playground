let cont = null;
let graph = "";

const examples = [
  `
let f[_X] = {<\\x[_X]. {nu _X1. nu _X2. (Succ (_X1, _X), x [_X1])}>(_X)} in

let map[_X] =
  {<\\f[_X].{<\\x[_L, _R, _X].
  let rec helper[_X] x2[_L, _R, _X] =
    case {Log} {x2[_L, _R, _X]} of
      {nu _L2. nu _R2. nu _X2. nu _X3. (
        y [_L, _R, _X, _L2, _R2, _X2],
        Leaf (_X3, _L2, _R2, _X2),
        z [_X3],
        M (_L2)
      )} ->
        let z2[_X] = {f[_X]} {z[_X]} in
        {helper[_X]}
        {nu _L2. nu _R2. nu _X2. nu _X3. nu _X4. (
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
{f [_X]}
({Log}
{
nu _X1. nu _X2. nu _X3. nu _X4. nu _X5. (
  Node (_X1, _X2, _X),
  Leaf (_X4 ,_L, _X3, _X1),
  Zero (_X4),
  Leaf (_X5, _X3, _R, _X2),
  Zero (_X5)
)
})
`,
  `
% (\\x[Y, X] y[Y, X].x[y[Y], X]) ()
%   Cons (Val1, Y, X)
%   Cons (Val2, Y, X)

let nodes1[_Y, _X] =
  {Log} {nu _X1. (Cons (_X1, _Y, _X), Val1 (_X1))} in

let nodes2[_Y, _X] =
  {Log} {nu _X1. (Cons (_X1, _Y, _X), Val2 (_X1))} in

{<\\ x[_Y, _X]. {<\\ y[_Y, _X]. {nu _Z. (x[_Z, _X], y[_Y, _Z])}>}>}
  {nodes1[_Y, _X]}
  {nodes1[_Y, _X]}
`,
  `
% case Cons (Val, _Y, _X) of
%   | nodes [Cons (h, _Y), _X] -> nodes [_Y, _X]
%   | otherwise -> Error

case {Log} {nu _Z1. (Cons (_Z1, _Y, _X), Val (_Z1))} of
  {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])} -> { nodes [_Y, _X] }
  | otherwise -> { Error }
`,
  `
% case (Cons (Val1, _Y, _X) of
%   | nodes [Cons (h, _Y), _X] -> Cons (Val2, nodes [_Y], _X)
%   | otherwise -> Error

case {Log} {nu _Z1. (Cons (_Z1, _Y, _X), Val1 (_Z1))} of
  {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])}
      -> { nu _U1. nu _U2. (Cons (_U1, _U2, _X), Val2 (_U1), nodes [_Y, _U2]) }
  | otherwise -> { Error }
    `,
  `
% case Cons (Val, _Y, _X) of
%   | nodes [Cons (h, _Y), _X] -> nodes [_Y, _X]
%   | otherwise -> Error

let rec f[_X] nodes[_Y, _X] =
  case {Log} {nodes[_Y, _X]} of
    {nu _W1. nu _W2. (nodes [_W2, _X], Cons (_W1, _Y, _W2), h [_W1])} -> {f [_X]} { nodes [_Y, _X] }
    | otherwise -> { Empty }
in
  {f[_X]}
    {nu _Z1. nu _Z2. nu _Z3. (Cons (_Z1, _Z2, _X), Val1 (_Z1), Cons (_Z3, _Y, _Z2), Val2 (_Z3))}
`,
];

window.addEventListener("DOMContentLoaded", (event) => {
  const graphviz = d3
    .select("#graph")
    .graphviz()
    .transition(function () {
      return d3.transition("main").ease(d3.easeLinear).delay(500).duration(500);
    });
  // .logEvents(true);
  const editor = document.getElementById("editor");

  const selector = document.getElementById("example-selector");
  selector.addEventListener("change", () => {
    console.log(selector.value);
    switch (selector.value) {
      case "map_lltree":
        editor.value = examples[0];
        break;
      case "append_dlists":
        editor.value = examples[1];
        break;
      case "pop_back_dlist_empty":
        editor.value = examples[2];
        break;
      case "pop_back_dlist_cons":
        editor.value = examples[3];
        break;
      case "pop_back_dlist_many":
        editor.value = examples[4];
        break;
      default:
        alert("error");
        console.log("error");
    }
    document.getElementById("result").innerText = "";
    graphviz.renderDot("digraph {start -> go; go -> go}");
  });

  console.log("DOM fully loaded and parsed");
  graphviz.renderDot("digraph {start -> go; go -> go}");

  document.getElementById("start-button").onclick = function () {
    const code = editor.value;

    try {
      const result = LambdaGT.rungrad(code);
      console.log("result", result);

      const [_, k, graph, value] = LambdaGT.extractk(result);
      console.log(k);
      cont = k[1];

      console.log("graph", graph);
      document.getElementById("result").innerText = value;
      graphviz.renderDot(graph);
    } catch (e) {
      alert(e);
    }
  };

  document.getElementById("go-button").onclick = function () {
    if (!cont) {
      alert("cannot proceed more");
      return;
    }

    try {
      const result = cont();
      console.log("result", result);

      const [_, k, graph, value] = LambdaGT.extractk(result);
      console.log(k);
      cont = k[1];

      console.log("graph", graph);
      document.getElementById("result").innerText = value;
      graphviz.renderDot(graph);
    } catch (e) {
      alert(e);
    }
  };
});
