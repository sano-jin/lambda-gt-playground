open Util

let exec = Eval.string_of_graph <. Eval.eval <. Parse.parse_exp
let () = print_endline @@ exec @@ read_file Sys.argv.(1)
