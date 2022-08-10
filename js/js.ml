(* open Util open Eval open Vis *)
open Util
open Js_of_ocaml

type 'a k = K of ((unit -> 'a k) option * 'a)

let rec k_of_cont = function
  | Either.Right v -> K (None, Js.string @@ Vis.dot_of_atoms v)
  | Either.Left (cont, v) ->
      K
        ( Some (fun () -> k_of_cont @@ Vis.app_cont cont v),
          Js.string @@ Vis.dot_of_atoms v )

let extract_k = function K k -> k
let eval_grad exp = k_of_cont @@ Vis.eval [] exp (Vis.Cont Either.right)

(* let exec code = let exp = Parse.parse_exp code in let rec helper = function |
   K (None, v) -> v | K (Some k, v) -> print_endline @@ string_of_graph v;
   print_endline @@ dot_of_atoms v; helper @@ k () in helper @@ eval_grad exp *)

let () =
  print_endline "LambdaGT";
  print_endline "LambdaGT";

  (* let graph = exec @@ read_file Sys.argv.(1) in print_endline @@ "// " ^
     Eval.string_of_graph_with_nu graph; print_endline @@ dot_of_atoms graph; *)
  Js.export "LambdaGT"
    (object%js
       method extractk = extract_k
       method parse = Parse.parse_exp <. Js.to_string
       method rungrad = eval_grad <. Parse.parse_exp <. Js.to_string
       method add x y = x +. y
       method abs x = abs_float x
       val zero = 0.
    end)
