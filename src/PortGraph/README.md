## port-graph-visualisation

A visualisation attempt of port hypergraphs

[elm-visualization](https://github.com/gampleman/elm-visualization)
をベースに変更を加えています．

とりあえず動くことを目標に作っているので，
refactoring は必須．

## About

Labelled port hypergraphs を綺麗に描画しようとしています．
大規模でランダム性の高いグラフではなく，
小規模で規則的なデータ構造を対象としています．

力学モデルを用いてグラフを描画していますが，
通常のものとは異なり，
バネの端点を頂点から少しずらすことで，
規則的なノードの配置を実現します．

バネの端点のずれ方は角度と距離で指定します．
この角度は，ファンクタ（頂点の名前とその頂点から出る辺の数の組）ごとに初期化されており，
ユーザが動的に指定することもできます．

## Port Graph

グラフのノードは以下の 2 種類ある．

- アトム: Port を持つ頂点
  - それぞれの port からは hyper でない edge が出て，
    port または unnamed hyperlink に接続される．
- Hyperlink: Port を持たない頂点．普通のグラフ理論の頂点．
  - 任意本の edge が出て，
    port または hyperlink に接続される．

同じポートや hyperlink から多重辺が出ることは想定していない．
あくまでポートや hyperlink から出る辺は一本で，他のポートに直接繋がるか，
ハイパーリンクに接続されるかのどちらか．

## Memo

```
- PortGraph/
  - ForceExtra.elm
  - PortGraph.elm
  - PortGraphExample.elm
  - Util.elm
  - ViewSettings.elm
  - VisGraph.elm

```

Settings を更新したら，グラフを全て再構築する．

- 効率が悪いように見えるかも知れない．
- が，どのみち描画をする際にグラフの全ての頂点（とそれらから伸びる辺の先の頂点）を訪問している．
- つまり，order は変わらない．

## Todo

- VisGraph と bootstrap を用いた slider の実装の分離．
  - とりあえず，ViewSettings.elm と言う名前にした．
- Settings を動的に反映させられるようにする．
- root に PortGraph.elm を作って，必要なものだけ公開する．
- Documentation.

## Futher Work

- VisGraph と bootstrap を用いた slider の実装の分離．
- グラフを更新した際に，
  visualisation のためのパラメータが初期化されてしまっているので，
  うまく引き継げるようにする．
  - Port Angles は，ファンクタごとの preset を更新して持っておく．
    - JSON で入出力できるようにする．
    - 個別の port angles を引き継ぐのは難しそうなので，後回し．
  - Spring settings はうまく引き継ぎたい．
- データ構造の整理．
  - 動的な更新ができるようにする．
  - port angle をできるだけ保ちたい．
  - まずはあまり差分を小さくすることについて考えなくても良いかも知れない．
- portCtrlPDistance は頂点間の距離に合わせて拡大させても良いかも知れない．
- Scroll していると，アトムの選択がうまくいかない（ズレる）ので，補正する必要がある．
- 命名の整理（Atom, Hyperlink, node, edge, link?）．
- port-graph-visualisation を playground から分離する．
- Settings のための JSON parser/docoder．

## Backend <-> Frontend Interop with JSON

The visualizer interops with the interpreter using the following JSON format.

```typescript
// Connected to `Port_` if portId exists, otherwise connected to `HL`.
type connectedTo = { nodeId: number; portId?: number };

// `angle` does not exists.
type port = { id: number; label: string; to: connectedTo };

type atom = { id: number; label: string; ports: port[] };

type hlink = { id: number; label: string; to: connectedTo[] };

type graph = { atoms: atom[]; hlinks: hlinks[] };

// `isEnded` represents whether the interpreter has ended the evaluation.
type message = { graph: graph; isEnded: boolean; info: string };
```

### Implementation Details

ForceExtra/ ディレクトリ以下のコードは，
elm-visualization の Force/ ディレクトリ以下のコードをそのまま使っているだけ．

ForceExtra.elm のみ変更を加えている．

#### Graph に対する操作．

`Main.elm` で，`graphData` を用いて，
Atoms, Hyperlinks の順で Graph に渡しているので，
この順に連続した整数を振らないとうまく動かない．

`elm-community/graph` にはほぼ全く依存していない．
サンプルプログラム (Main.elm) で使っているだけ．

`elm-community/graph` は効率化のために，`elm-community/intdict` を使っているが，
PortGraph では，とりあえずは普通の Dict を用いている．

### References

[elm-visualization](https://github.com/gampleman/elm-visualization)

- [Force directed graph with zoom](https://github.com/gampleman/elm-visualization/blob/master/examples/ForceDirectedGraphWithZoom.elm)

[svg tutorial](http://defghi1977.html.xdomain.jp/tech/svgMemo/svgMemo_03.htm)

[MSNL Playgrund](https://mishina-haruto.github.io/MSNL/#)

[Full the height](https://www.educative.io/answers/how-to-make-the-div-fill-the-height-of-the-remaining-screen-space)

## Done

- Implement Decoders.
- Implement ports.
- Main.elm の分割（Port を用いる部分とグラフ描画などの部分を分離）．
- PortGraph から `Context` と言う単語を省く．
