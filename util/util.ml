(** Utility functions.

    - 基本的なコンビネータ，双方向連結リストなど *)

include Combinator
(** include basic combinators *)

module OptionExtra = Option_extra
(** load extra functions for the option type *)

module ListExtra = List_extra
(** load extra functions for a list *)

module ResultExtra = Result_extra
(** load extra functions for a result *)

module DebugPrint = Debug_print
(** load functions for debug printing *)

module QuoSet = Quo_set
(** load functions for debug printing *)

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

let explode = List.of_seq <. String.to_seq
let implode = String.of_seq <. List.to_seq
let update_ref f r = r := f !r

(** a function that always returns fresh numbers (from 1) *)
let unique =
  (* let counter = ref 0 in *)
  let counter = ref 100 in
  fun () ->
    incr counter;
    !counter

(** time measurement *)
let measure_time f x =
  let start = Unix.gettimeofday () in
  let res = f x in
  let stop = Unix.gettimeofday () in
  (res, stop -. start)

(** printy print the current local time in [YY-MM-DD HH:MM:SS] *)
let time_str () =
  let time_now = Unix.localtime @@ Unix.time () in
  Printf.sprintf "%02d-%02d-%02d %02d:%02d:%02d" (time_now.tm_year + 1900)
    (time_now.tm_mon + 1) (time_now.tm_mday + 1) time_now.tm_hour
    time_now.tm_min time_now.tm_sec

(** quote the input string *)
let quote str = "`" ^ str ^ "`"

let quote_block str = "\n```\n" ^ str ^ "\n```\n"

exception ImplementationError of string
(** implementation error *)

let impl_error message = raise (ImplementationError message)
