# 水泳選手マネジメントシステム（Swim Manager）

## 開発者向け重要事項

**Cursor AIを使用する際の注意事項：**
- すべての指示を実行する前に、必ず `requirements.md` ファイルを読み込んでください
- `requirements.md` の内容に基づいて、適切な実装を行ってください
- Rails開発ベストプラクティス（セクション13）に従ってください
- 命名規則、セキュリティ要件、パフォーマンス要件を満たしてください

## プロジェクト構成（モノレポ）

```
swim_manager/
├── backend/           # Ruby on Rails API
├── mobile/           # Flutter モバイルアプリ
├── shared/           # 共通リソース
│   ├── docs/        # API仕様書・設計書
│   ├── assets/      # 共通画像・アイコン
│   └── scripts/     # 開発・運用スクリプト
├── Dockerfile        # バックエンド用Docker設定
├── docker-compose.yml
└── requirements.md   # システム要件定義書
```

## 開発環境のセットアップ

### バックエンド（Rails API）

#### Docker環境での開発

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

4. データベースのセットアップ（新規ウィンドウを開いて操作）
   ```bash
   docker-compose exec web rails db:create db:migrate db:seed
   ```

5. ブラウザでアクセス
   - http://localhost:3000 にアクセス

#### ローカル環境での開発

1. 必要な環境をインストール
   ```bash
   # Ruby 3.2.8をインストール（rbenv使用の場合）
   rbenv install 3.2.8
   rbenv global 3.2.8
   
   # PostgreSQL 15をインストール
   brew install postgresql@15
   brew services start postgresql@15
   ```

2. プロジェクトセットアップ
   ```bash
   cd backend
   bundle install
   yarn install
   ```

3. データベースのセットアップ
   ```bash
   rails db:create db:migrate db:seed
   ```

4. 開発サーバーを起動
   ```bash
   # Rails + CSS監視を同時に起動
   bin/dev
   
   # または個別に起動
   rails server -p 3000
   rails tailwindcss:watch  # 別ターミナルで実行
   ```

#### テストユーザー情報

- 選手ログインの場合
     メールアドレス：player1@test　パスワード：123123
- 管理者ログインの場合
     メールアドレス：coach1@test　パスワード：123123

### モバイルアプリ（Flutter）

```bash
# Flutterの開発環境セットアップ
cd mobile
# 今後のFlutterプロジェクト作成時に詳細を追加予定
```

## API仕様

バックエンドAPIは以下のエンドポイントを提供しています：

- **認証**: `/api/v1/auth/login`, `/api/v1/auth/logout`
- **ユーザー**: `/api/v1/mypage`, `/api/v1/members`
- **スケジュール**: `/api/v1/calendar`
- **出席管理**: `/api/v1/attendance`
- **目標管理**: `/api/v1/objectives`
- **管理者機能**: `/api/v1/admin/*`

詳細なAPI仕様書は `shared/docs/` ディレクトリに今後追加予定です。

## トラブルシューティング

### Docker環境

- コンテナを停止する場合
  ```bash
  docker-compose down
  ```

- データベースをリセットする場合
  ```bash
  docker-compose down -v
  docker-compose up --build
  docker-compose exec web rails db:create db:migrate db:seed
  ```

- ログを確認する場合
  ```bash
  docker-compose logs web
  ```

### ローカル環境

- サーバーが起動しない場合
  ```bash
  # PIDファイルを削除
  rm -f backend/tmp/pids/server.pid
  
  # ポートが使用中の場合
  lsof -ti:3000 | xargs kill -9
  ```

- データベース接続エラーの場合
  ```bash
  # PostgreSQLが起動していることを確認
  brew services list | grep postgresql
  
  # データベースを再作成
  cd backend
  rails db:drop db:create db:migrate db:seed
  ```
