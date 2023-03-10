open Util
open Parse
open Eval

let links_of_atoms atoms = List.concat_map snd @@ atoms

(** local link と free link を分ける *)
let unzip_links =
  List.partition_map @@ function LocalLink l -> Left l | FreeLink f -> Right f

type connected_to = Port of int * int | HLink of int
type port_ = { port_id : int; port_label : string; port_to_ : connected_to }
type atom_ = { atom_id : int; atom_label : string; ports : port_ list }

type hlink_ = {
  hlink_id : int;
  hlink_label : string;
  hlink_to_ : connected_to list;
}

type graph_ = { atoms_ : atom_ list; hlinks_ : hlink_ list }

(** アトムリストを可視化しやすいデータ構造に変換する *)
let portgraph_of_atoms (atoms : graph) =
  (* リンク名からポートの集合への写像を作る． *)
  let link_map =
    let helper ((atom_i, _), args) =
      List.mapi (fun arg_i link -> (link, (atom_i, arg_i))) args
    in
    List.concat_map helper atoms
  in
  let link_dict = ListExtra.gather link_map in

  (* 端点が二つしか無いリンク (normal link) と，そうでは無いものに分離する．*)
  let normal_link_dict, hlink_dict =
    let helper = function
      | LocalLink x, [ p1; p2 ] -> Either.Left (x, (p1, p2))
      | mapping -> Either.Right mapping
    in
    List.partition_map helper link_dict
  in

  (* リンク名から，hlink の id への写像 *)
  let atoms_length = List.length atoms in
  let free_link_names =
    List.mapi (fun i (x, _) -> (x, i + atoms_length)) hlink_dict
  in
  let get_link_i x =
    Option.value (List.assoc_opt x free_link_names) ~default:0
  in

  (* リンク名 x と 接続元の atom と port の id の組から，接続先の情報を取得する． *)
  let normal_link_dict =
    List.map (first @@ fun x -> LocalLink x) normal_link_dict
  in
  let connected_to_of x atom_port_id =
    match List.assoc_opt x normal_link_dict with
    | Some ((a1, p1), (a2, p2)) ->
        if (a1, p1) = atom_port_id then Port (a2, p2) else Port (a1, p1)
    | None -> HLink (get_link_i x)
  in

  (* hyperlinks *)
  let hlinks_ =
    let hlink_of x =
      let hlink_id = get_link_i x in
      {
        hlink_id;
        hlink_label = (match x with FreeLink x -> x | _ -> "");
        hlink_to_ =
          List.map (fun (atom_id, port_id) -> Port (atom_id, port_id))
          @@ List.assoc x hlink_dict;
      }
    in
    List.map (hlink_of <. fst) hlink_dict
  in

  (* atoms *)
  let atoms_ =
    (* (int * atom_name) * link list *)
    let atom_of ((atom_id, atom_name), links) =
      {
        atom_id;
        atom_label = string_of_atom_name atom_name;
        ports =
          List.mapi
            (fun port_id x ->
              {
                port_id;
                port_label = string_of_int (port_id + 1);
                port_to_ = connected_to_of x (atom_id, port_id);
              })
            links;
      }
    in
    List.map atom_of atoms
  in
  { atoms_; hlinks_ }

let authors : Yojson.Basic.t list =
  [
    `Assoc
      [ ("name", `String "Jason Hickey"); ("affiliation", `String "Google") ];
    `Assoc
      [
        ("name", `String "Anil Madhavapeddy");
        ("affiliation", `String "Cambridge");
      ];
    `Assoc
      [
        ("name", `String "Yaron Minsky"); ("affiliation", `String "Jane Street");
      ];
  ]

(** 可視化のために，アトムリストを dot に変換する *)
let dot_of_atoms (atoms : graph) =
  (* リンク名からポートの集合への写像を作る． *)
  let link_map =
    let helper ((atom_i, _), args) =
      List.mapi (fun arg_i link -> (link, (atom_i, arg_i))) args
    in
    List.concat_map helper atoms
  in
  let link_dict = ListExtra.gather link_map in

  (* 端点が二つしか無いリンク (normal link) と，そうでは無いものに分離する．*)
  let normal_links, link_dict =
    let helper = function
      | LocalLink x, [ p1; p2 ] -> Either.Left (x, (p1, p2))
      | mapping -> Either.Right mapping
    in
    List.partition_map helper link_dict
  in

  (* normal link を dot の文字列に変換する． *)
  let normal_links_str =
    let helper (_, ((i1, _), (i2, _))) =
      Printf.sprintf "\tAtom_%d -> Atom_%d;" i1 i2
    in
    String.concat "\n" @@ List.map helper normal_links
  in

  let stage = Util.unique () in
  let links = List.sort_uniq compare @@ links_of_atoms atoms in
  let locallinks, freelinks = unzip_links @@ links in

  let local_link_setting locallink =
    if List.mem_assoc (LocalLink locallink) link_dict then
      Some
        ("\tL_" ^ string_of_int stage ^ "_" ^ string_of_int locallink
       ^ "[label=\"\", shape=point];")
    else None
  in
  let local_link_settings =
    String.concat "\n" @@ List.filter_map local_link_setting locallinks
  in

  let free_link_setting freelink =
    "\tF_" ^ freelink ^ "[label=\"" ^ freelink ^ "\", shape=plain];"
  in
  let free_link_settings =
    String.concat "\n" @@ List.map free_link_setting freelinks
  in

  let atom_setting _atom_id (((i, atom_name), _) : Eval.atom) =
    let v = string_of_atom_name atom_name in
    "\tAtom_" ^ string_of_int i ^ "[label=\"" ^ v ^ "\"];"
  in
  let atom_settings = String.concat "\n" @@ List.mapi atom_setting atoms in

  let string_of_link = function
    | LocalLink i -> "L_" ^ string_of_int stage ^ "_" ^ string_of_int i
    | FreeLink f -> "F_" ^ f
  in

  let atom_links _atom_id ((i, _), args) =
    let helper link =
      if List.mem_assoc link link_dict then
        Some ("\tAtom_" ^ string_of_int i ^ " -> " ^ string_of_link link ^ ";")
      else None
    in
    List.filter_map helper args
  in

  let atoms_links =
    String.concat "\n" @@ List.concat @@ List.mapi atom_links atoms
  in

  let dot =
    [
      "digraph G {";
      "\tgraph [layout = LAYOUT];";
      "\tedge [arrowhead = none];";
      atom_settings;
      local_link_settings;
      free_link_settings;
      normal_links_str;
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
  | BinOp (f, op, e1, e2) -> (
      eval theta e1 @@ k
      @@ fun v1 ->
      eval theta e2 @@ k
      @@ fun v2 ->
      match (v1, v2) with
      | [ ((_, Int i1), xs1) ], [ ((_, Int i2), _) ] ->
          app_cont cont [ ((unique (), Int (f i1 i2)), xs1) ]
      | _ ->
          failwith @@ "integers are expected for " ^ op ^ " but were "
          ^ string_of_graph v1 ^ " and " ^ string_of_graph v2)
  | Graph graph ->
      app_cont cont @@ reid @@ fuse_fusions @@ synthesis theta graph
  | App (e1, e2) -> (
      eval theta e1 @@ k
      @@ fun v1 ->
      eval theta e2 @@ k
      @@ fun v2 ->
      match v1 with
      | [ ((_, Lam (ctx, e, theta)), _) ] ->
          let ctx = ctx_of ctx in
          let theta = (ctx, v2) :: theta in
          eval theta e cont
      | [ (((_, RecLam (ctx1, ctx2, e, theta)), _) as rec_lam) ] ->
          let ctx1 = ctx_of ctx1 in
          let ctx2 = ctx_of ctx2 in
          let theta = (ctx1, [ rec_lam ]) :: (ctx2, v2) :: theta in
          eval theta e cont
      | [ ((_, Constr "Log"), _) ] -> Either.Left (cont, v2)
      | _ -> failwith @@ "function expected but got " ^ string_of_graph v1)
  | Case (e1, template, e2, e3) -> (
      eval theta e1 @@ k
      @@ fun v1 ->
      let _, template = alpha100 template in
      match match_ template v1 with
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
      let rec_lam = (Util.unique (), RecLam (ctx1, ctx2, e1, theta)) in
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
  print_endline @@ "// " ^ Eval.string_of_graph graph;
  print_newline ();
  print_endline @@ dot_of_atoms graph
