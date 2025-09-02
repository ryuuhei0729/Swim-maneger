# Mobile App (Flutter)

水泳選手マネジメントシステムのFlutterモバイルアプリケーション

## 概要

このディレクトリには、Flutterで開発されるモバイルアプリケーションのソースコードが格納されます。

## 技術スタック

- **フレームワーク**: Flutter
- **言語**: Dart
- **状態管理**: Provider
- **HTTP通信**: dio
- **認証**: JWT Token（既存APIと連携）
- **セキュアストレージ**: flutter_secure_storage

## セットアップ

### 前提条件
- Flutter SDK (3.0以上)
- Dart SDK
- Android Studio / Xcode（エミュレーター用）

### インストール手順

```bash
# プロジェクトディレクトリに移動
cd mobile/swim_manager_mobile

# 依存関係をインストール
flutter pub get

# アプリを実行（iOS）
flutter run

# アプリを実行（Android）
flutter run -d android
```

## プロジェクト構造

```
lib/
├── constants/          # 定数定義
│   ├── app_config.dart # アプリ設定
│   └── strings.dart    # 文字列定数
├── models/             # データモデル
│   └── user.dart       # ユーザーモデル
├── providers/          # 状態管理
│   └── auth_provider.dart # 認証プロバイダー
├── screens/            # 画面
│   ├── auth/           # 認証関連画面
│   │   └── login_screen.dart
│   └── home/           # ホーム画面
│       └── home_screen.dart
├── services/           # サービス層
│   ├── api_service.dart # API通信
│   └── auth_service.dart # 認証サービス
├── utils/              # ユーティリティ
├── widgets/            # カスタムウィジェット
│   ├── custom_button.dart
│   └── custom_text_field.dart
└── main.dart           # エントリーポイント
```

## 実装済み機能

### Phase 3.1: Flutterプロジェクトセットアップ ✅
- [x] Flutter開発環境の構築
- [x] プロジェクト構造の設計
- [x] 依存関係の設定（dio, provider等）
- [x] 環境設定（開発・本番）

### Phase 3.2: 認証・ログイン機能 ✅
- [x] ログイン画面の実装
- [x] JWT認証の実装
- [x] セッション管理
- [x] パスワードリセット機能

## 開発予定機能

### フェーズ1（基本機能）
- [ ] ホーム画面（お知らせ・カレンダー）
- [ ] マイページ（プロフィール編集）
- [ ] メンバー一覧
- [ ] 出席管理

### フェーズ2（拡張機能）
- [ ] 練習記録表示
- [ ] 目標管理
- [ ] レース管理
- [ ] プッシュ通知

## API連携

既存のRails APIエンドポイント（`/api/v1/`）を活用してデータを取得・更新します。

### 認証フロー
1. ユーザーがログイン画面でメールアドレスとパスワードを入力
2. APIにログインリクエストを送信
3. JWTトークンとリフレッシュトークンを受信
4. トークンをセキュアストレージに保存
5. 以降のAPIリクエストでトークンを自動的に付与

### トークン管理
- アクセストークン: 短期間有効（1時間）
- リフレッシュトークン: 長期間有効（30日）
- 自動トークン更新機能付き

## 開発ガイドライン

### コード規約
- Dartの公式コーディング規約に従う
- ファイル名はsnake_case
- クラス名はPascalCase
- 変数名はcamelCase

### 状態管理
- Providerパターンを使用
- 各機能ごとにプロバイダーを作成
- グローバル状態は最小限に抑制

### エラーハンドリング
- ネットワークエラーの適切な処理
- ユーザーフレンドリーなエラーメッセージ
- ローディング状態の表示

## テスト

```bash
# ユニットテスト実行
flutter test

# 統合テスト実行
flutter test integration_test/
```

## ビルド

```bash
# Android APKビルド
flutter build apk

# iOSビルド
flutter build ios

# Webビルド
flutter build web
```

## トラブルシューティング

### よくある問題

1. **依存関係のエラー**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **エミュレーターが起動しない**
   - Android Studio / Xcodeでエミュレーターを手動起動
   - `flutter doctor`で環境を確認

3. **API接続エラー**
   - バックエンドサーバーが起動しているか確認
   - `lib/constants/app_config.dart`のURL設定を確認

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。
