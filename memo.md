% Memo

# Repairing λGT

グラフと型（生成文法）を入力にとり，
preprocessing したグラフと，
型が生成するグラフの集合を出力する．

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

# このリポジトリについて

このリポジトリは，
visualiser に渡すために JSON へ変換するコードと，
javascript として解釈実行するためのコードを含んでいる．

TODO: それぞれの使い方を整理してまとめる．

visualiser のために，アトムに id を振っているけど，
この id は不要かも知れない．
現状の visualiser は使っていないはず．
コードを綺麗にするために，これを削除するのはありかも．
どうしても必要になったら，Magic で物理アドレスを取得してそれを使えば良い？
