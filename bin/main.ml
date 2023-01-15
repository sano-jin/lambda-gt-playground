open Util
open QuoSet

let () = print_endline @@ string_of_quo_set q3
let exec = Eval.string_of_graph_with_nu <. Eval.eval <. Parse.parse_exp
let () = print_endline @@ exec @@ read_file Sys.argv.(1)
