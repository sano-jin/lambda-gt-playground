# Lambda GT Playground

A online evaluator and a visualiser of the Lambda GT language.

Try this at [TODO](https://example.com).

The interpreter is based on
[sano-jin/lambda-gt-alpha](https://github.com/sano-jin/lambda-gt-alpha).
See [its README](https://github.com/sano-jin/lambda-gt-alpha#syntax)
for the syntax and more information of the language.

The visualiser (and the whole playground) is implemented with Elm.
See below for further information.

### Development

Prerequisites:

- opam
- elm

Installation:

```bash
git clone https://github.com/sano-jin/lambda-gt-playground.git

# First, build the interpreter.
# Move to the directory.
cd lambda-gt-playground/lambda-gt-gamma
# Install dependency.
opam install .
# Build and move the output javascript code to TODO.
./deploy.sh

# Back to the root directory.
cd ..
```

Usage:

At the root directory, run following:

```bash
elm-app start
```

Then, access <http://localhost:8080> with your browser.

### Todo

Interpreter

- JSON を出力できるようにする．

Visualiser

- `Context` と言う単語を省く．
- 画面の整理．
- データ構造の整理．
  - 動的な更新ができるようにする．
  - port angle をできるだけ保ちたい．
  - まずはあまり差分を小さくすることについて考えなくても良いかも知れない．
- portCtrlPDistance は頂点間の距離に合わせて拡大させても良いかも知れない．
- Scroll していると，アトムの選択がうまくいかない（ズレる）ので，補正する必要がある．
- 命名の整理（Atom, Hyperlink, node, edge, link?）．

## port-graph-visualisation

A visualisation attempt of port hypergraphs

[elm-visualization](https://github.com/gampleman/elm-visualization)
をベースに変更を加えています．

とりあえず動くことを目標に作っているので，
refactoring は必須．

### About

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

### Port Graph

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

### Todo

- `Context` と言う単語を省く．
- 画面の整理．
- データ構造の整理．
  - 動的な更新ができるようにする．
  - port angle をできるだけ保ちたい．
  - まずはあまり差分を小さくすることについて考えなくても良いかも知れない．
- portCtrlPDistance は頂点間の距離に合わせて拡大させても良いかも知れない．
- Scroll していると，アトムの選択がうまくいかない（ズレる）ので，補正する必要がある．
- 命名の整理（Atom, Hyperlink, node, edge, link?）．

#### JSON

The visualizer interops with the interpreter using the following JSON format.

```typescript
// `portId` exists if `connectedTo` is a Port, otherwise it does not exist.
type connectedTo = { nodeId: number; portId?: number };

// `angle` does not exists.
type port = { id: number; label: string; to: connectedTo };

type atom = { id: number; label: string; ports: port[] };

type hlink = { id: number; label: string; to: connectedTo[] };

type graph = { atoms: atom[]; hlinks: hlinks[] };

// `isEnded` represents whether the interpreter has ended the evaluation.
type message = { graph: graph; isEnded: boolean; info: string };
```

For example, as follows:

```typescript
const graph = {
  atoms: [
    {
      id: 0,
      label: "Cons",
      ports: [
        { id: 0, label: "1", to: { nodeId: 1, portId: 0 } },
        { id: 1, label: "2", to: { nodeId: 2, portId: 2 } },
        { id: 2, label: "3", to: { nodeId: 7 } },
      ],
    },
    {
      id: 1,
      label: "1",
      ports: [{ id: 0, label: "1", to: { nodeId: 0, portId: 0 } }],
    },
    {
      id: 2,
      label: "Cons",
      ports: [
        { id: 0, label: "1", to: { nodeId: 3, portId: 0 } },
        { id: 1, label: "2", to: { nodeId: 4, portId: 2 } },
        { id: 2, label: "3", to: { nodeId: 0 } },
      ],
    },
    {
      id: 3,
      label: "1",
      ports: [{ id: 0, label: "1", to: { nodeId: 2, portId: 0 } }],
    },
    {
      id: 4,
      label: "Cons",
      ports: [
        { id: 0, label: "1", to: { nodeId: 5, portId: 0 } },
        { id: 1, label: "2", to: { nodeId: 6, portId: 2 } },
        { id: 2, label: "3", to: { nodeId: 0 } },
      ],
    },
    {
      id: 5,
      label: "1",
      ports: [{ id: 0, label: "1", to: { nodeId: 4, portId: 0 } }],
    },
    {
      id: 6,
      label: "Nil",
      ports: [{ id: 0, label: "1", to: { nodeId: 4, portId: 0 } }],
    },
  ],
  hlinks: [{ id: 7, label: "X", to: [{ nodeId: 0, portId: 2 }] }],
};
```

### Technical Details

Port hypergraph を描画できるようにしたい．

- アトム（ポートありの頂点）とハイパーリンク（ポートなしの頂点）からなるグラフを描画する．
- ポートの位置（角度）は固定できるようにする．
  - それぞれの頂点の，それぞれのポートごとに，角度を調整するスライダを用意する．
- 辺は 3 次ベジェ曲線で描画する．
  - Hyperlink は単なるポートなしの頂点．
  - 同じポートや hyperlink から多重辺が出ることは想定していない．

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

## Done

- Implement Decoders.
- Implement ports.
- Main.elm の分割（Port を用いる部分とグラフ描画などの部分を分離）．
