(** Syntax *)

type ctx = string * string list

type atom_name =
  | PConstr of string  (** constructor name *)
  | PLam of ctx * exp  (** lambda abstraction *)

(** graph *)
and graph =
  | Zero
  | Atom of atom_name * string list  (** atom. e.g. a(_X, _Y) *)
  | Ctx of ctx  (** graph context. e.g. x[_X, _Y] *)
  | Mol of graph * graph  (** molecule *)
  | Nu of string * graph  (** hyperlink creation *)

(** exp *)
and exp =
  | Graph of graph  (** graph *)
  | Case of exp * graph * exp * exp  (** Case of *)
  | App of exp * exp  (** Apply *)
  | LetRec of ctx * ctx * exp * exp  (** let rec f x = e1 in e2 *)
  | Let of ctx * exp * exp  (** let x = e1 in e2 *)

let rec string_of_exp = function
  | Graph graph -> "{" ^ string_of_graph graph ^ "}"
  | Case (e1, template, e2, e3) ->
      "(case " ^ string_of_exp e1 ^ " of {" ^ string_of_graph template ^ "} -> "
      ^ string_of_exp e2 ^ " | otherwise -> " ^ string_of_exp e3 ^ ")"
  | App (e1, e2) -> "(" ^ string_of_exp e1 ^ ", " ^ string_of_exp e2 ^ ")"
  | LetRec (ctx1, ctx2, e1, e2) ->
      "(let rec " ^ string_of_ctx ctx1 ^ " " ^ string_of_ctx ctx2 ^ " = "
      ^ string_of_exp e1 ^ " in " ^ string_of_exp e2 ^ ")"
  | Let (ctx, e1, e2) ->
      "(let " ^ string_of_ctx ctx ^ " = " ^ string_of_exp e1 ^ " in "
      ^ string_of_exp e2 ^ ")"

and string_of_atom_name = function
  | PConstr name -> name
  | PLam (ctx, e) -> "<\\ " ^ string_of_ctx ctx ^ " . " ^ string_of_exp e ^ ">"

and string_of_graph = function
  | Zero -> "0"
  | Atom (v, args) ->
      string_of_atom_name v ^ " (" ^ String.concat ", " args ^ ")"
  | Ctx (x, args) -> string_of_ctx (x, args)
  | Mol (g1, g2) -> "(" ^ string_of_graph g1 ^ ", " ^ string_of_graph g2 ^ ")"
  | Nu (x, g) -> "nu " ^ x ^ ". " ^ string_of_graph g

and string_of_ctx (x, args) = x ^ " [" ^ String.concat ", " args ^ "]"

type rule = graph * graph

let string_of_rule (lhs, rhs) =
  string_of_graph lhs ^ " ---> " ^ string_of_graph rhs
