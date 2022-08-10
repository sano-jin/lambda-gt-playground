open Util
open Util.OptionExtra
open Syntax

let subst_link_of_link link_env x =
  Option.value (List.assoc_opt x link_env) ~default:x

let subst_link_of_atom link_env (v, args) =
  (v, List.map (subst_link_of_link link_env) args)

let subst_link_of_atoms link_env = (List.map <. subst_link_of_atom) link_env

(** target graph において同じリンク名となるリンクに対応している，テンプレートのリンクをまとめる， *)
let gather_links link_env =
  let link_family =
    List.map snd @@ ListExtra.gather @@ List.map swap link_env
  in
  List.map (List.map (fun x -> LocalLink x)) link_family

(** link_env から補った，局所リンク同士を引数にもつ fusion を作る *)
let local2local_fusions_of_link_env link_env =
  let link_sets = gather_links link_env in
  let helper = function [] -> [] | x :: xs -> List.map (fusion_of x) xs in
  List.concat_map helper link_sets

(* マッチング対象のグラフでは自由リンクだが，テンプレートのリンクでは局所リンクであった場合に， 自由リンクと局所リンクの fusion
   を作ってグラフに補う*)
let local2free_fusions_of_link_env link_env =
  let free_fusions = List.filter (is_free_link <. snd) link_env in
  List.map (fun (x, y) -> fusion_of (LocalLink x) y) free_fusions

(* マッチング対象のグラフのリンク名をテンプレートのリンク名に変換する *)
let subst_links_graph link_env rest_graph =
  let helper = function
    | x, (LocalLink _ as y) -> [ (y, LocalLink x) ]
    | _ -> []
  in
  let inverse_link_env = List.concat_map helper link_env in
  (* マッチング対象のグラフのリンク名をテンプレートのリンク名に変換する *)
  subst_link_of_atoms inverse_link_env rest_graph

(** find_atoms をした後の link_env の後処理をする． 自由リンクと局所リンクを引数にもつ fusion を作る．
    マッチング対象のグラフの局所リンク名をルール左辺のものに合わせる． *)
let rest_graph_of (link_env, rest_graph) =
  subst_links_graph link_env rest_graph
  @ local2local_fusions_of_link_env link_env
  @ local2free_fusions_of_link_env link_env

let has_link_of_atom x (_, args) = List.exists (( = ) x) args
let has_links_of_atom xs atom = List.exists (flip has_link_of_atom atom) xs
let has_link_of_atoms x = List.exists @@ List.exists @@ ( = ) x <. snd

let free_links_of_atoms =
  List.concat_map @@ List.filter is_free_link <. List.map snd

let links_of_atoms = List.concat_map snd

(** 全てのアトムをマッチさせる．ただし，必要に応じて fusion を補う atoms_lhs はまだマッチングしていない LHS のアトムのリスト．
    atoms_rest はマッチング対象のグラフにおいて，まだマッチングを試していないアトムのリスト *)
let match_ctxs prerr ctxs_lhs target_graph =
  let rec match_ctxs theta target_graph = function
    | [] -> Some (theta, target_graph)
    | ctx :: rest_lhs_ctxs ->
        prerr @@ "matching ctx " ^ string_of_ctx ctx ^ " to "
        ^ string_of_graph target_graph;
        (* ターゲットのグラフのマッチングを試していないアトムのリストを引数にとる *)
        let free_links = snd ctx in
        let rec traverse_links traversed_graph target_graph traversed_links
            traversing_links =
          prerr @@ "traverse_links traversing_links = "
          ^ ListExtra.string_of_list string_of_link traversing_links;
          let traversed_graph2, rest =
            List.partition (has_links_of_atom traversing_links) target_graph
          in
          prerr @@ "traversed_graph2 = " ^ string_of_graph traversed_graph2;
          if traversed_graph2 = [] then (
            prerr @@ "traversing ended with matched graph = "
            ^ string_of_graph traversed_graph;
            if
              (* ListExtra.set_eq free_links (links_of_atoms traversed_graph)
                 && *)
              ListExtra.set_minus
                (free_links_of_atoms traversed_graph)
                free_links
              = []
            then (
              prerr @@ "ctx matching succeeded";
              Some (traversed_graph, rest))
            else (
              prerr @@ "ctx matching failed";
              None))
          else
            let new_links = links_of_atoms traversed_graph2 in
            let traversed_links = traversing_links @ traversed_links in
            let new_links = ListExtra.set_minus new_links traversed_links in
            let new_links = ListExtra.set_minus new_links free_links in
            traverse_links
              (traversed_graph2 @ traversed_graph)
              rest traversing_links new_links
        in

        let rec match_ctx tested_target_atoms = function
          | [] -> None (* 全て失敗 *)
          | target_atom :: rest_target_atoms ->
              (let* matched_graph, rest_target_graph =
                 traverse_links [] target_graph [] (snd ctx)
               in
               match_ctxs
                 ((ctx, matched_graph) :: theta)
                 rest_target_graph rest_lhs_ctxs)
              <|> fun _ ->
              match_ctx (target_atom :: tested_target_atoms) rest_target_atoms
        in
        match_ctx [] target_graph
  in
  match_ctxs [] target_graph ctxs_lhs
