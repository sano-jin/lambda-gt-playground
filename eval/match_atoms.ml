open Util
open Util.OptionExtra
open Syntax

(* link_env は，ルールの左辺の局所リンクから，マッチング対象のグラフのリンクへの射． [check_link link_env
   (target_link, lhs_link)] *)
let check_link link_env = function
  | FreeLink x, FreeLink y -> if x = y then Some link_env else None
  | LocalLink _, FreeLink _ ->
      None (* cannot match a local link with a free link *)
  | x, LocalLink y -> (
      match List.assoc_opt y link_env with
      | None -> Some ((y, x) :: link_env) (* bind if unbounded *)
      | Some z ->
          if x = z then Some link_env (* if matched with the environment *)
          else None)

let match_links_of_args link_env args1 args2 =
  let* args1_2 = ListExtra.combine_opt args1 args2 in
  OptionExtra.foldM check_link link_env args1_2

let match_links_of_atom link_env (v1, args1) (v2, args2) =
  if v1 <> v2 then None else match_links_of_args link_env args1 args2

(** 全てのアトムをマッチさせる．ただし，必要に応じて fusion を補う atoms_lhs はまだマッチングしていない LHS のアトムのリスト．
    atoms_rest はマッチング対象のグラフにおいて，まだマッチングを試していないアトムのリスト *)
let find_atoms f target_graph atoms_lhs =
  (* find_atoms link_env graph atoms_rest atoms_lhs *)
  let rec find_atoms link_env target_graph = function
    | [] -> f (link_env, target_graph)
    | atom :: rest_lhs_atoms ->
        (* ターゲットのグラフのマッチングを試していないアトムのリストを引数にとる *)
        let rec find_atom tested_target_atoms = function
          | [] -> None (* 全て失敗 *)
          | target_atom :: rest_target_atoms ->
              (let* link_env = match_links_of_atom link_env target_atom atom in
               let rest_target_graph =
                 List.rev_append tested_target_atoms rest_target_atoms
               in
               find_atoms link_env rest_target_graph rest_lhs_atoms)
              <|> fun _ ->
              find_atom (target_atom :: tested_target_atoms) rest_target_atoms
        in
        find_atom [] target_graph
  in
  find_atoms [] target_graph atoms_lhs
