open Util
open Util.OptionExtra
open Syntax
open Preprocess
open Match_ctxs
open Match

(** lambda abstraction atom を評価した時に，クロージャにする *)
let make_closure theta = function
  | Lam (ctx, e, _), links -> (Lam (ctx, e, theta), links)
  | atom -> atom

let make_closures theta atoms = List.map (make_closure theta) atoms

(** matching 後の代入 *)
let check_functor (v1, args1) (v2, args2) =
  (v1, List.length args1) = (v2, List.length args2)

(** matching 後の代入 *)
let synthesis (theta : theta) template_graph =
  let i, (atoms, ctxs) = alpha 0 [] template_graph in
  let atoms = make_closures theta atoms in
  let subst_graph i ctx =
    match List.find_opt (check_functor ctx <. fst) theta with
    | None -> failwith @@ "unbound graph context " ^ fst ctx
    | Some (ctx2, graph) ->
        let link_theta = List.combine (snd ctx2) (snd ctx) in
        let i, graph = alpha_atoms (i, link_theta) graph in
        (i, graph)
  in
  let _, graphs = List.fold_left_map subst_graph i ctxs in
  atoms @ List.concat graphs

let get_local_fusion_opt = function
  | Constr "><", [ (LocalLink _ as x); y ]
  | Constr "><", [ y; (LocalLink _ as x) ] ->
      Some (x, y)
  | _ -> None

let fuse_fusions graph =
  let fuse_fusion graph =
    let+ ((_, _) as fusion), (g1, g2) =
      ListExtra.rev_break_opt get_local_fusion_opt graph
    in
    subst_link_of_atoms [ fusion ] (List.rev_append g1 g2)
  in
  whileM fuse_fusion graph

let match_and_synthesis graph1 lhs graph2 =
  match match_atoms lhs graph1 with
  | Some theta -> Some (synthesis theta graph2)
  | _ -> None
