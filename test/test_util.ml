(* test util *)
open Util
module StrQuoSet = QuoSet.Make (String)

let s1 = [ "X"; "Y" ]
let s2 = [ "Y"; "Z" ]
let s3 = [ "Z"; "W" ]
let s4 = [ "U"; "V" ]
let s5 = [ "X"; "W" ]

let test () =
  let q1 = StrQuoSet.of_lists [ s1; s1; s3 ] in
  let q2 = StrQuoSet.of_lists [ s4; s2; s4; s5 ] in
  let q3 = StrQuoSet.merge q1 q2 in
  print_endline @@ StrQuoSet.to_string id q1;
  print_endline @@ StrQuoSet.to_string id q2;
  print_endline @@ StrQuoSet.to_string id q3;

  let q4 = StrQuoSet.of_lists [ s1; s1; s1; s1; s1 ] in
  print_endline @@ StrQuoSet.to_string id q4
