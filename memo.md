# Memo

A visualisation attempt of port hypergraphs

[elm-visualization](https://github.com/gampleman/elm-visualization)
をベースに変更を加えています．

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

## Todo

portCtrlPDistance は頂点間の距離に合わせて拡大させても良いかも知れない．

Scroll していると，アトムの選択がうまくいかない（ズレる）ので，補正する必要がある．

## Memo

Port hypergraph を描画できるようにしたい．

- アトム（ポートありの頂点）とハイパーリンク（ポートなしの頂点）からなるグラフを描画する．
- ポートの位置（角度）は固定できるようにする．
  - それぞれの頂点の，それぞれのポートごとに，角度を調整するスライダを用意する．
- できるだけ，ポートの方向に接続先の頂点が来るようにしたい．
  - 普通の力学モデルだけでなくて，
    1. ポートの先の距離をほぼ固定できるようにする？
       - 固定先への引力が発生するようにする？
       - 引力の大きさを調整するスライダを作る？
    2. ポートの方向へ誘導する？
       - ポートの方向への引力が発生するようにする？
       - ポートからの距離に反比例する大きさにする？
- 辺は 3 次ベジェ曲線で描画する．
  - Hyperlink はどうするか？
    - ダミーノードを用意して，それを通るようにする．
      - うまく曲線で描画できるようにしたいけど，それはまた今度．
  - 多重辺はどうするか？
    - ダミーノードを用意して，それを通るような曲線を描けると良い．
    - ポート間のベクトルに平行に制御点を配置してやれば良さそう．
    - 同じポートから多重辺が出ることは想定していないので，考慮せずとも大丈夫な気がしてきた．
      - あくまでポートから出る辺は一本で，他のポートに直接繋がるか，ハイパーリンクに接続されるかの違いしかない．

## Definition of Port Graphs

グラフのノードは以下の 2 種類ある．

- アトム: Port を持つ頂点
  - それぞれの port からは hyper でない edge が出て，
    port または unnamed hyperlink に接続される．
- Hyperlink: Port を持たない頂点．普通のグラフ理論の頂点．
  - 任意本の edge が出て，
    port または hyperlink に接続される．
  - 【補足】Hyperlink 同士が接続されることはない．．．と仮定しても良いはず．
  - 【補足】複数の Hyperlink の fusion である場合は，カンマで区切って表すことにする？
  - 【補足】自由リンクの場合は名前を表示して，局所リンクの時は表示しない（空文字列）とすれば良い．

## Graph に対する操作．

実は `elm-community/graph` にはほぼ全く依存していない．

- サンプルプログラム (Main.elm) で使っているだけ．

使っているメソッド．

- nodes
- edges
- mapContexts
  - Context は，`{ node, incoming_edges, outgoing_edges }`
  - Node は id とラベルだけ．
- update
- fromNodeLabelsAndEdgePairs

`elm-community/graph` は効率化のために，`elm-community/intdict` を使っている．

- とりあえずは，普通の Dict で実装するか．

## Memo

Port hypergraph を描画できるようにしたい．

- ポートにラベルをふれるようにしたい．
- ポートの位置（角度）は固定できるようにしたい．
  - それぞれの頂点の，それぞれのポートごとに，角度を調整するスライダを用意する．
  - 将来的には，同じ名前の頂点のポートはまとめて操作できるようにする．
- できるだけ，ポートの方向に接続先の頂点が来るようにしたい．
  - 普通の力学モデルだけでなくて，
    1. ポートの先の距離をほぼ固定できるようにする？
       - 固定先への引力が発生するようにする？
       - 引力の大きさを調整するスライダを作る？
    2. ポートの方向へ誘導する？
       - ポートの方向への引力が発生するようにする？
       - ポートからの距離に反比例する大きさにする？
- 辺は 3 次ベジェ曲線で描画する．
  - Hyperlink はどうするか？
    - ダミーノードを用意して，それを通るようにする．
      - うまく曲線で描画できるようにしたいけど，それはまた今度．
  - 多重辺はどうするか？
    - ダミーノードを用意して，それを通るような曲線を描けると良い．
    - ポート間のベクトルに平行に制御点を配置してやれば良さそう．
    - 同じポートから多重辺が出ることは想定していないので，考慮せずとも大丈夫な気がしてきた．
      - あくまでポートから出る辺は一本で，他のポートに直接繋がるか，ハイパーリンクに接続されるかの違いしかない．

elm-bootstrap は slider がなさげなので，
elm-mdl を使うのが良さそう？

- <https://debois.github.io/elm-mdl/#sliders>

## References

[elm-visualization](https://github.com/gampleman/elm-visualization)

- [Force directed graph with zoom](https://github.com/gampleman/elm-visualization/blob/master/examples/ForceDirectedGraphWithZoom.elm)

[svg tutorial](http://defghi1977.html.xdomain.jp/tech/svgMemo/svgMemo_03.htm)

## Old

elm-bootstrap は slider がなさげなので，
elm-mdl を使うのが良さそう？

- <https://debois.github.io/elm-mdl/#sliders>
- elm-mdl はすでに死んでいる．
- 自前で Html.input を使って作った方が良さそうと言う結論に達した．

[elm-slider](https://package.elm-lang.org/packages/carwow/elm-slider/latest/SingleSlider)

- 結局使わなかった．
- 自前で実装した．

### Done

Port の位置をファンクタごとに調整できるようにする．
