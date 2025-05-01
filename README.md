# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

# Swim Manager

## 開発環境のセットアップ

### Dockerを使用する場合（推奨）

1. DockerとDocker Composeをインストール
   - [Docker Desktop](https://www.docker.com/products/docker-desktop)をダウンロードしてインストール

2. リポジトリをクローン
   ```bash
   git clone https://github.com/your-username/swim_manager.git
   cd swim_manager
   ```

3. Dockerコンテナを起動
   ```bash
   docker-compose up --build
   ```

4. データベースのセットアップ
   ```bash
   docker-compose exec web rails db:create db:migrate
   ```

5. ブラウザでアクセス
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
