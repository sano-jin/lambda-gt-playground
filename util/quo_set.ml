open Option_extra
open Combinator

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
      restriction). Returns with [Some] if it succeeds to insert, returns [None]
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

  (** Convert a list to an equivalence class (set). *)
  let ec_of_list = EC.of_list

  (** Convert to a list from an equivalence class (set). *)
  let list_of_ec = EC.elements

  (** Convert a quotient set to a list of lists. *)
  let lists_of = List.map EC.elements

  (** Returns the support set *)
  let support = List.concat <. lists_of

  (** Convert to a quotient set from a list of lists. *)
  let of_lists ls =
    let sets = List.map EC.of_list ls in
    List.fold_right insert sets empty

  (** Choose a representative element in the given equivalence set. *)
  let choose = EC.choose

  (** Return a representative element in the equivalence set that has the given
      element. [repr elem ec]. *)
  let repr = EC.choose <.. List.find <. EC.mem

  (** Restrict the support set of the given quotient set with the given support
      set. [restrict support quo_set]. *)
  let restrict =
    List.filter (not <. EC.is_empty) <.. List.map <. EC.filter <. flip List.mem

  (** Extend the support set of the quitient set. [extend support quo_set]. *)
  let extend = flip @@ List.fold_right (insert <. EC.singleton)

  (** Generate a quotient set (reflective transitive closure). *)
  let generate =
    let rec helper rq = function
      | [] -> rq
      | h :: t -> (
          match insert_opt h t with
          | None -> helper (h :: rq) t
          | Some t -> helper rq t)
    in
    helper []

  (** Merge quotient sets, i.e., generate a new equivalence relation. *)
  let merge q1 q2 = generate (q1 @ q2)

  (** Fuse x with y in a given quotient set. *)
  let fuse x y = merge @@ of_lists [ [ x; y ] ]

  (** Canonical surjection. *)
  let surjection = List.find <. EC.mem

  (** Simplify the quotient set.

      @deprecated 2022/1/17 *)
  let simplify q = List.filter (fun ec -> EC.cardinal ec > 1) q

  (** [graph q] returns a graph (relation). E.g.,
      [graph (of_lists \[\[1; 2\]; \[3; 4; 5\]\]) = \[(1, 2); (2, 1); (3, 4); (4, 5); (5, 3)\]]. *)
  let graph =
    let helper ls =
      List.concat_map (fun e1 -> List.map (fun e2 -> (e1, e2)) ls) ls
    in
    List.sort compare <. List.concat_map (helper <. EC.elements)

  let string_of_graph string_of_elem graph =
    let string_of_pair (e1, e2) =
      "(" ^ string_of_elem e1 ^ ", " ^ string_of_elem e2 ^ ")"
    in
    "{" ^ String.concat ", " (List.map string_of_pair graph) ^ "}"

  (** Test if the quotient set [q1] is finer than the quotient set [q2]. *)
  let is_finer q1 q2 =
    let helper ec1 =
      let elem1 = EC.choose ec1 in
      let ec2 = List.find (EC.mem elem1) q2 in
      EC.subset ec1 ec2
    in
    List.for_all helper q1

  (** Pretty print a quotient set. *)
  let to_string string_of_elem =
    let string_of_set string_of_elem elem =
      "{" ^ String.concat ", " (List.map string_of_elem elem) ^ "}"
    in
    string_of_set (string_of_set string_of_elem) <. lists_of
end
