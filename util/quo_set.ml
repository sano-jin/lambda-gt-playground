open Option_extra

(** Copied from Set module *)
module type OrderedType = sig
  type t

  val compare : t -> t -> int
end

(** Quotient set の自前実装（あとで Union-Find に置き換える） *)
module Make (Ord : OrderedType) = struct
  type elt = Ord.t

  module EC = Set.Make (Ord)
  (** Equivalence class. *)

  type t = EC.t list

  (** Create a new empty quotient set. *)
  let empty = []

  (** Insert an equivalence class to a quotient set. Note that the second
      argument must be a quotient set (not just a list of sets without any
      restriction). Returns with [Some] if it succeed to insert, return [None]
      otherwise. *)
  let rec insert_opt ec = function
    | [] -> None
    | h :: t ->
        if EC.disjoint ec h then
          let+ t = insert_opt ec t in
          h :: t
        else Some (EC.union ec h :: t)

  (** Insert an equivalence class to a quotient set. Note that the second
      argument must be a quotient set (not just a list of sets without any
      restriction). *)
  let insert ec q = Option.value (insert_opt ec q) ~default:(ec :: q)

  (** Merge quotient sets, i.e., generate a new equivalence relation. *)
  let merge q1 q2 =
    let rec helper rq = function
      | [] -> rq
      | h :: t -> (
          match insert_opt h t with
          | None -> helper (h :: rq) t
          | Some t -> helper rq t)
    in
    helper [] (q1 @ q2)

  (** Convert a list to an equivalence class (set). *)
  let ec_of_list = EC.of_list

  (** Convert to a list from an equivalence class (set). *)
  let list_of_ec = EC.elements

  (** Convert a quotient set to a list of lists. *)
  let to_lists q = List.map EC.elements q

  (** Convert to a quotient set from a list of lists. *)
  let of_lists ls =
    let sets = List.map EC.of_list ls in
    List.fold_right insert sets empty

  (** Pretty print a quotient set *)
  let to_string string_of_elem q =
    let ls = to_lists q in
    let string_of_ec ec =
      "{" ^ String.concat ", " (List.map string_of_elem ec) ^ "}"
    in
    "{" ^ String.concat ", " (List.map string_of_ec ls) ^ "}"
end
