open Parse
open Util

type link =
  | FreeLink of string  (** free link *)
  | LocalLink of int  (** local link *)

let string_of_link = function
  | FreeLink link -> link
  | LocalLink i -> "_L" ^ string_of_int i

let map_local_link f = function LocalLink l -> LocalLink (f l) | link -> link

type atom_name =
  | Constr of string  (** constructor name *)
  | Lam of Parse.ctx * exp * theta  (** lambda abstraction *)
  | RecLam of Parse.ctx * Parse.ctx * exp * theta  (** lambda abstraction *)

and atom = atom_name * link list
and ctx = string * link list

and graph = atom list
(** graph as data*)

and theta = (ctx * graph) list

type e_graph = atom list * ctx list
(** graph on the left/right-hand side of rules *)

let string_of_atom_name = function
  | Constr name -> name
  | Lam (ctx, e, _) ->
      "<\\ " ^ string_of_ctx ctx ^ " . " ^ string_of_exp e ^ ">"
  | RecLam (ctx1, ctx2, e, _) ->
      "<rec " ^ string_of_ctx ctx1 ^ " = \\ " ^ string_of_ctx ctx2 ^ " . "
      ^ string_of_exp e ^ ">"

let string_of_atom (atom_name, args) =
  string_of_atom_name atom_name
  ^ " ("
  ^ String.concat ", " (List.map string_of_link args)
  ^ ")"

let string_of_ctx (name, args) =
  name ^ " [" ^ String.concat ", " (List.map string_of_link args) ^ "]"

let string_of_e_graph (atoms, gctxs) =
  "{"
  ^ String.concat ", "
      (List.map string_of_atom atoms @ List.map string_of_ctx gctxs)
  ^ "}"

let string_of_ctxs ctxs =
  "{" ^ String.concat ", " (List.map string_of_ctx ctxs) ^ "}"

type link_env = (int * link) list
(** target graph のリンクから template graph のリンクへの対応 *)

let string_of_link_env =
  let helper (x, y) = string_of_link (LocalLink x) ^ "->" ^ string_of_link y in
  ListExtra.string_of_list helper

let fusion_of x y = (Constr "><", [ x; y ])
let is_free_link = function LocalLink _ -> false | FreeLink _ -> true

let local_links_of_graph =
  List.concat_map (List.filter (not <. is_free_link)) <. List.map snd

let string_of_graph atoms =
  let graph_str = String.concat ", " (List.map string_of_atom atoms) in
  "{" ^ graph_str ^ "}"

let string_of_theta (theta : theta) =
  let helper (ctx, graph) =
    string_of_ctx ctx ^ " -> " ^ string_of_graph graph
  in
  ListExtra.string_of_list helper theta

let string_of_graph_with_nu atoms =
  let graph_str = String.concat ", " (List.map string_of_atom atoms) in
  let local_links = List.sort_uniq compare @@ local_links_of_graph atoms in
  let local_links_str =
    let helper local_link = "nu " ^ string_of_link local_link ^ ". " in
    String.concat "" @@ List.map helper local_links
  in
  if local_links <> [] && List.length atoms > 1 then
    "{" ^ local_links_str ^ "(" ^ graph_str ^ ")}"
  else "{" ^ local_links_str ^ graph_str ^ "}"
