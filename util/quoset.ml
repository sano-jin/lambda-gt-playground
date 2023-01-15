open Combinator
open Option_extra

module SSet = Set.Make (String)
(** Quotient set の自前実装（あとで Union-Find に置き換える） *)

type quo_set = SSet.t list
(** free links are represented with a quotient set of link names. *)

(** create a new empty quotient set. *)
let make = SSet.empty

(** merge quotient set, i.e., generate a new equivalence relation. *)
let merge q1 q2 =
  let merge_set_opt ec1 ec2 =
    if SSet.disjoint ec1 ec2 then None else Some (SSet.union ec1 ec2)
  in
  let rec insert ec = function
    | [] -> None
    | h :: t -> (
        match merge_set_opt ec h with
        | Some h -> Some (h :: t)
        | None ->
            let+ t = insert ec t in
            h :: t)
  in
  let rec merge = function
    | _, [] -> None
    | rq, h :: t -> (
        match insert h (List.rev_append rq t) with
        | None -> merge (h :: rq, t)
        | Some t -> Some (rq, t))
  in
  uncurry ( @ ) @@ whileM merge ([], q1 @ q2)

let string_of_quo_set q =
  let string_of_ec ec = "{" ^ String.concat ", " (SSet.elements ec) ^ "}" in
  "{" ^ String.concat ", " (List.map string_of_ec q) ^ "}"

let s1 = SSet.of_list [ "X"; "Y" ]
let s2 = SSet.of_list [ "Y"; "Z" ]
let s3 = SSet.of_list [ "Z"; "W" ]
let s4 = SSet.of_list [ "U"; "V" ]
let q1 : quo_set = [ s1; s3 ]
let q2 : quo_set = [ s2; s4 ]
let q3 : quo_set = merge q1 q2
let () = print_endline @@ string_of_quo_set q3
