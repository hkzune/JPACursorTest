# Java Sample Project – JPA Cursor Test

※このリポジトリにはシェルスクリプトが含まれます。
　クローン時に改行コードをCRLFに変換しないように設定することをお勧めします。

## 説明

このリポジトリは、以下の記事で紹介したサンプルプロジェクトです。  

記事リンク（仮）: [https://example.com](https://example.com)

---

## 使いかた

※dockerコンテナを実行できる環境が必要です。

<br>

1. コンソールで以下のディレクトリに移動します：

```bash
cd compose/JpaCursorTest
```

<br>

2. 次のコマンドを実行してサーバー群を起動します：

```bash
docker compose up
```

<br>

3. 以下の3つのサーバーが起動します：

- アプリケーションサーバー（WildFly）
- Webサーバー（Vite ベースのフロントエンド）
- DBサーバー（Microsoft SQL Server）

<br>

4. ブラウザで http://localhost:5173 にアクセスすると、Web UI が表示されます。

<br>

5. Web UI 内の「test」ボタンをクリックすると、WildFly 側の API を呼び出します。

<br>

## ライセンス

このプロジェクトには正式なライセンスは設定されていません。
個人学習用途での使用を想定しています。
商用利用や再配布はご遠慮ください。
