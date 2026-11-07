# oracle-xplan-guide

Oracle の実行計画の読み方を学ぶためのノート。`docs/` の HTML を GitHub Pages でそのまま公開する。ビルドの工程はない。

## ローカルでのプレビュー

```sh
cd docs && python3 -m http.server 8000
```

ブラウザで <http://127.0.0.1:8000/> を開く。

## 構成

| パス | 内容 |
|------|------|
| `docs/index.html` | トップ（目標・章のカード・方針） |
| `docs/chapters/*.html` | 各章 |
| `docs/assets/site.css` | 共通スタイル（配色トークン、図の SVG 用クラスを含む） |
| `docs/assets/nav.js` | 章の情報（題名・タグ・色）。トップのカード・全画面メニュー・次の章へのリンクを作る |
| `docs/assets/theme.js` | 配色の選択を復元する（既定は暗い配色） |
| `sql/` | 各章で実行する SQL |
| `compose.yaml` | 学習用の Oracle（Docker） |

## 学習用 Oracle 環境

[docs/chapters/00-setup.html](docs/chapters/00-setup.html) を参照する。

## 公開

`main` に push すると GitHub Actions が `docs/` を GitHub Pages にデプロイする。
初回のみ、リポジトリの Settings → Pages → Source を「GitHub Actions」にする。
