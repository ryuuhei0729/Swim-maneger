# README

## 開発者向け重要事項

**Cursor AIを使用する際の注意事項：**
- すべての指示を実行する前に、必ず `requirements.md` ファイルを読み込んでください
- `requirements.md` の内容に基づいて、適切な実装を行ってください
- Rails開発ベストプラクティス（セクション13）に従ってください
- 命名規則、セキュリティ要件、パフォーマンス要件を満たしてください

## Dockerを使用した開発環境のセットアップ

1. DockerとDocker Composeをインストール
   - [Docker Desktop](https://www.docker.com/products/docker-desktop)をダウンロードしてインストール

2. リポジトリをクローン
   ```bash
   git clone https://github.com/your-username/swim_manager.git
   ```

3. ディレクトリ内に移動
   ```bash
   cd swim_manager
   ```

4. Dockerコンテナを起動
   ```bash
   docker-compose up --build
   ```

5. データベースのセットアップ（新規ウィンドウを開いて操作）
   ```bash
   docker-compose exec web rails db:create db:migrate
   ```

6. ブラウザでアクセス
   - http://localhost:3000 にアクセス

7. 任意のユーザーでログイン
   - 選手ログインの場合
        メールアドレス：player1@test　パスワード：123123
   - 管理者ログインの場合
        メールアドレス：coach1@test　パスワード：123123

### トラブルシューティング

- コンテナを停止する場合
  ```bash
  docker-compose down
  ```

- データベースをリセットする場合
  ```bash
  docker-compose down -v
  docker-compose up --build
  ```
