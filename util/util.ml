(** Utility functions.

    - 基本的なコンビネータ，双方向連結リストなど *)

include Combinator
(** include basic combinators *)

module OptionExtra = Option_extra
(** load extra functions for the option type *)

module ListExtra = List_extra
(** load extra functions for a list *)

(** その他の共用関数 *)

(** 入出力のための関数 *)

(** read lines from the given file *)
let read_file name =
  let ic = open_in name in
  let try_read () = try Some (input_line ic) with End_of_file -> None in
  let rec loop acc =
    match try_read () with
    | Some s -> loop (s :: acc)
    | None ->
        close_in ic;
        String.concat "\n" @@ List.rev acc
  in
  loop []


(** a function that always returns fresh numbers (from 1) *)
let unique =
  (* let counter = ref 0 in *)
  let counter = ref 100 in
  fun () ->
    incr counter;
    !counter

