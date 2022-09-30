open Util

(** find_atoms をした後の link_env の後処理をする *)
let match_ (atoms_lhs, ctxs_lhs) target_graph =
  match
    Match_atoms.find_atoms
      (Match_ctxs.match_ctxs ctxs_lhs <. Match_ctxs.rest_graph_of)
      target_graph atoms_lhs
  with
  | Some (theta, []) -> Some theta
  | _ -> None
