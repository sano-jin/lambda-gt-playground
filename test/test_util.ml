(* test util *)
open Util
module StrQuoSet = QuoSet.Make (String)
module IQSet = QuoSet.Make (Int)

let s1 = [ "X"; "Y" ]
let s2 = [ "Y"; "Z" ]
let s3 = [ "Z"; "W" ]
let s4 = [ "U"; "V" ]
let s5 = [ "X"; "W" ]
let s6 = [ "X"; "Y"; "Z"; "W"; "U"; "V" ]

let test () =
  let q1 = StrQuoSet.of_lists [ s1; s1; s3 ] in
  let q2 = StrQuoSet.of_lists [ s4; s2; s4; s5 ] in
  let q3 = StrQuoSet.merge q1 q2 in
  print_endline @@ "q1 = " ^ StrQuoSet.to_string id q1;
  print_endline @@ "q2 = " ^ StrQuoSet.to_string id q2;
  print_endline @@ "q3 = " ^ StrQuoSet.to_string id q3;

  let q6 = StrQuoSet.of_lists [ s6 ] in
  print_endline @@ "q6 = " ^ StrQuoSet.to_string id q6;

  print_endline @@ "is_finer q3 q2 = " ^ string_of_bool
  @@ StrQuoSet.is_finer q2 q3;
  print_endline @@ "is_finer q6 q3 = " ^ string_of_bool
  @@ StrQuoSet.is_finer q3 q6;

  let q4 = StrQuoSet.of_lists [ s1; s1; s1; s1; s1 ] in
  print_endline @@ "q4 = " ^ StrQuoSet.to_string id q4;

  let graph = IQSet.graph (IQSet.of_lists [ [ 1; 2 ]; [ 3; 4; 5 ] ]) in
  print_endline @@ "graph = " ^ IQSet.string_of_graph string_of_int graph;
  print_endline @@ "graph: "
  ^ string_of_bool
      (graph
      = List.sort compare
          [
            (1, 1);
            (1, 2);
            (2, 1);
            (2, 2);
            (3, 3);
            (3, 4);
            (3, 5);
            (4, 3);
            (4, 4);
            (4, 5);
            (5, 3);
            (5, 4);
            (5, 5);
          ])
