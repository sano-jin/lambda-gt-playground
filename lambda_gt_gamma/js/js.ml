(* open Util open Eval open Vis *)
open Util
open Js_of_ocaml

type ('a, 'b) k = K of ((unit -> ('a, 'b) k) option * 'a * 'b)

let rec k_of_cont = function
  | Either.Right v ->
      print_endline @@ "Right1";
      print_endline @@ "Right2" ^ Vis.pretty_graph v;
      print_endline @@ "Right3";
      K
        ( None,
          Js.string @@ Vis.pretty_graph v,
          Js.string @@ Eval.string_of_graph v )
  | Either.Left (cont, v) ->
      print_endline @@ "Left1";
      print_endline @@ "Left2" ^ Vis.pretty_graph v;
      print_endline @@ "Left3";
      K
        ( Some (fun () -> k_of_cont @@ Vis.app_cont cont v),
          Js.string @@ Vis.pretty_graph v,
          Js.string @@ Eval.string_of_graph v )

let extract_k = function K k -> k
let eval_grad exp = k_of_cont @@ Vis.eval [] exp (Vis.Cont Either.right)

(* let exec code = let exp = Parse.parse_exp code in let rec helper = function |
   K (None, v) -> v | K (Some k, v) -> print_endline @@ string_of_graph v;
   print_endline @@ dot_of_atoms v; helper @@ k () in helper @@ eval_grad exp *)

let () =
  print_endline "LambdaGT v3";

  (* let graph = exec @@ read_file Sys.argv.(1) in print_endline @@ "// " ^
     Eval.string_of_graph_with_nu graph; print_endline @@ dot_of_atoms graph; *)
  Js.export "LambdaGT"
    (object%js
       method extractk = extract_k
       method parse = Parse.parse_exp <. Js.to_string
       method rungrad = eval_grad <. Parse.parse_exp <. Js.to_string
    end)
