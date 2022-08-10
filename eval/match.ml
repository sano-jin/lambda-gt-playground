open Util
open Syntax

(** find_atoms をした後の link_env の後処理をする *)
let match_atoms prerr ((atoms_lhs : atom list), ctxs_lhs) target_graph =
  match
    Match_atoms.find_atoms prerr
      (Match_ctxs.match_ctxs prerr ctxs_lhs <. Match_ctxs.rest_graph_of)
      atoms_lhs target_graph
  with
  | Some (theta, []) -> Some theta
  | Some (_, rest_graph) ->
      prerr @@ "partial matching succeeded but the graph "
      ^ string_of_graph rest_graph ^ " left";
      None
  | _ -> None
