open Util

let usage_msg = "append [-verbose] <file> [<file2>]"
let verbose = ref false
let input_files = ref []
let anon_fun filename = input_files := filename :: !input_files
let speclist = [ ("-verbose", Arg.Set verbose, "Output debug information") ]

let exec exp =
  prerr_endline @@ "input\n" ^ DebugPrint.indent_lines exp;
  prerr_newline ();
  let exp = Parse.parse_exp exp in
  prerr_endline @@ "running...";
  let prerr = if !verbose then prerr_endline else ignore in
  let graph = Eval.eval prerr exp in
  prerr_endline @@ Eval.string_of_graph_with_nu graph

let () =
  Arg.parse speclist anon_fun usage_msg;
  if !input_files = [] then failwith @@ "give me a file name!"
  else
    let code = String.concat "\n" @@ List.map read_file !input_files in
    exec code
