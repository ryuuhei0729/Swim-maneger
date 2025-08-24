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
   docker-compose exec web rails db:create db:migrate
   ```

5. ブラウザでアクセス
   - http://localhost:3000 にアクセス

6. 任意のユーザーでログイン
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
