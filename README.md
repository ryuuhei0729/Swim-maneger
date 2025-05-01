# README
## 開発環境のセットアップ

### Dockerを使用します

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
