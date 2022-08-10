open Util
open Parse
open Eval

let links_of_atoms atoms = List.concat_map snd atoms

let unzip_links =
  List.partition_map @@ function LocalLink l -> Left l | FreeLink f -> Right f

let dot_of_atoms atoms =
  let links = List.sort_uniq compare @@ links_of_atoms atoms in
  let locallinks, freelinks = unzip_links @@ links in

  let local_link_setting locallink =
    "\tL_" ^ string_of_int locallink ^ "[label=\"\", shape=point];"
  in
  let local_link_settings =
    String.concat "\n" @@ List.map local_link_setting locallinks
  in

  let free_link_setting freelink =
    "\tF_" ^ freelink ^ "[label=\"" ^ freelink ^ "\", shape=plain];"
  in
  let free_link_settings =
    String.concat "\n" @@ List.map free_link_setting freelinks
  in

  let atom_setting atom_id (v, _) =
    let v = string_of_atom_name v in
    "\tAtom_" ^ string_of_int atom_id ^ "[label=\"" ^ v ^ "\"];"
  in
  let atom_settings = String.concat "\n" @@ List.mapi atom_setting atoms in

  let string_of_link = function
    | LocalLink i -> "L_" ^ string_of_int i
    | FreeLink f -> "F_" ^ f
  in

  let atom_links atom_id (_, args) =
    let helper link =
      "\tAtom_" ^ string_of_int atom_id ^ " -> " ^ string_of_link link ^ ";"
    in
    List.map helper args
  in

  let atoms_links =
    String.concat "\n" @@ List.concat @@ List.mapi atom_links atoms
  in

  let dot =
    [
      "digraph G {\n\tgraph [layout=neato]; \n\tedge [arrowhead = none];";
      local_link_settings;
      free_link_settings;
      atom_settings;
      atoms_links;
      "}";
    ]
  in
  String.concat "\n\n" dot

type cont = Cont of (Eval.graph -> (cont * Eval.graph, Eval.graph) Either.t)

let app_cont = function Cont cont -> cont

let rec eval theta exp cont =
  let k cont = Cont cont in
  match exp with
  | Graph graph -> app_cont cont @@ fuse_fusions @@ synthesis theta graph
  | App (e1, e2) -> (
      eval theta e1 @@ k
      @@ fun v1 ->
      eval theta e2 @@ k
      @@ fun v2 ->
      match v1 with
      | [ (Lam (ctx, e, theta), _) ] ->
          let ctx = ctx_of ctx in
          let theta = (ctx, v2) :: theta in
          eval theta e cont
      | [ ((RecLam (ctx1, ctx2, e, theta), _) as rec_lam) ] ->
          let ctx1 = ctx_of ctx1 in
          let ctx2 = ctx_of ctx2 in
          let theta = (ctx1, [ rec_lam ]) :: (ctx2, v2) :: theta in
          eval theta e cont
      | [ (Constr "Log", _) ] -> Either.Left (cont, v2)
      | _ -> failwith @@ "function expected but got " ^ string_of_graph v1)
  | Case (e1, template, e2, e3) -> (
      eval theta e1 @@ k
      @@ fun v1 ->
      let _, template = alpha100 template in
      match match_atoms template v1 with
      | None -> eval theta e3 cont
      | Some theta2 ->
          let theta = theta2 @ theta in
          eval theta e2 cont)
  | Let (ctx, e1, e2) ->
      eval theta e1 @@ k
      @@ fun v1 ->
      let ctx = ctx_of ctx in
      let theta = (ctx, v1) :: theta in
      eval theta e2 cont
  | LetRec (ctx1, ctx2, e1, e2) ->
      let rec_lam = RecLam (ctx1, ctx2, e1, theta) in
      let ctx = ctx_of ctx1 in
      let theta = (ctx, [ (rec_lam, snd ctx) ]) :: theta in
      eval theta e2 cont

let exec code =
  let exp = Parse.parse_exp code in
  let rec helper = function
    | Either.Right v -> v
    | Either.Left (cont, v) ->
        print_endline @@ string_of_graph v;
        print_endline @@ dot_of_atoms v;
        helper @@ app_cont cont v
  in
  helper @@ eval [] exp (Cont Either.right)

let vis () =
  let graph = exec @@ read_file Sys.argv.(1) in
  print_endline @@ "// " ^ Eval.string_of_graph_with_nu graph;
  print_newline ();
  print_endline @@ dot_of_atoms graph
