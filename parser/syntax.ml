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
