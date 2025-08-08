# 水泳選手マネジメントシステム 要件定義書

## 0. 開発固定前提（AIプロンプト参照用）
本プロジェクトで「毎回共通」の前提。個別タスクの指示では、差分や上書きが必要な事項のみ記載すれば良い。

- ランタイム/フレームワーク: Ruby on Rails 8.0（Ruby はチーム標準の安定版）
- データベース: PostgreSQL
- 認証: Devise（Web: Cookie セッション, API: セッション/トークン拡張）。API トークンは `user_auths.authentication_token` を利用
- 認可: Pundit（ポリシーで一元管理）
- フロント: ERB + Turbo + Stimulus + Tailwind CSS
- ファイルアップロード: Active Storage（本番 S3 / 開発 Disk）
- バックグラウンド: Active Job + Sidekiq（Redis）
- キャッシュ: Redis Cache Store
- ページネーション: Kaminari
- シリアライザ: Jbuilder（または AMS）。原則 Jbuilder を優先
- ルーティング方針: Web（既定）/ 管理 `/admin` 
- コーディング規約: `requirements.md` の「13. Rails開発ベストプラクティス」に準拠（命名/設計/API/セキュリティ/性能）
- ディレクトリ/アーキ構成: `architecture.md` に準拠
- 実行/開発コマンド（標準）: `bin/dev`（開発起動）, `bin/rails spec`（テスト）
- 禁止/制約（共通）:
  - 既存マイグレーションの書換え禁止（新規マイグレーションで対応）
  - 破壊的な API 変更禁止（後方互換）
  - パッケージの無断バージョンアップ禁止
  - 資格情報の直書き/コミット禁止（`credentials`/環境変数を使用）
  - 既存 UI の DOM 構造/Tailwind クラス大幅変更は要相談


## 1. システム概要

### 1.1 システム名
水泳選手マネジメントシステム（Swim Manager）

### 1.2 システムの目的
水泳チームの選手、コーチ、監督、マネージャーが効率的にチーム運営を行えるWebアプリケーション

### 1.3 対象ユーザー
- **Admin（管理者）**: コーチ、監督、マネージャー
- **Player（選手）**: 水泳選手

## 2. ユーザー管理・認証機能

### 2.1 ユーザータイプ
- **player**: 選手（0）
- **manager**: マネージャー（1）
- **coach**: コーチ（2）
- **director**: 監督（3）

### 2.2 認証機能
- [x] Deviseを使用した認証システム
- [x] メールアドレス・パスワード認証
- [x] パスワードリセット機能
- [x] セッション管理
- [x] API認証トークン機能
- [x] 権限管理（Admin/Player分離）

### 2.3 ユーザー情報
- 名前、世代、性別、誕生日
- プロフィール画像（Active Storage）
- 自己紹介文

## 3. メンバー管理機能

### 3.1 選手情報管理
- [x] 選手一覧表示
- [x] 選手詳細情報表示
- [x] 選手情報編集
- [x] 選手追加・削除
- [x] 一括インポート機能（Excel）
- [x] 世代別管理

### 3.2 管理者機能
- [x] 選手情報の一括管理
- [x] 選手の権限管理
- [x] 選手の参加状況確認

## 4. 予定管理機能

### 4.1 イベント管理
- [x] 練習予定の作成・編集・削除
- [x] 大会予定の作成・編集・削除
- [x] カレンダー表示
- [x] イベントタイプ分類（練習/大会）
- [x] 場所、メモ情報

### 4.2 スケジュール管理
- [x] 月間・週間スケジュール表示
- [x] イベント詳細表示
- [x] スケジュール一括インポート

## 5. 出欠管理機能

### 5.1 出席状況管理
- [x] イベント別出席状況確認
- [x] 出席・欠席・遅刻の管理
- [x] 個別出席状況編集
- [x] 一括出席状況更新
- [x] 出席状況の履歴管理

### 5.2 出席統計
- [x] 選手別出席率
- [x] イベント別参加者数
- [x] 出席状況レポート

## 6. 練習記録管理機能

### 6.1 練習ログ管理
- [x] 練習内容の記録（泳法、距離、本数×セット、サークル）
- [x] 練習メモ機能
- [x] 練習ログの一覧表示
- [x] 練習ログの詳細表示

### 6.2 タイム記録
- [x] 選手別タイム入力
- [x] 一括タイム入力機能
- [x] タイム履歴管理
- [x] 練習参加者管理

### 6.3 練習分析
- [x] 選手別練習記録
- [x] 練習内容の統計
- [x] タイム推移の確認

## 7. 大会管理機能（記録）

### 7.1 記録管理
- [x] 大会記録の登録・編集
- [x] 泳法別記録管理
- [x] 記録の詳細情報（メモ、動画URL）
- [x] 記録の履歴管理

### 7.2 記録分析
- [x] 選手別ベストタイム
- [x] 泳法別記録一覧
- [x] 記録の推移分析
- [x] スプリットタイム管理

## 8. 大会管理機能（エントリー）

### 8.1 エントリー管理
- [x] 大会エントリーの登録・編集
- [x] 泳法・距離別エントリー
- [x] エントリータイム管理
- [x] エントリー状況確認

### 8.2 エントリー分析
- [x] 大会別エントリー一覧
- [x] 選手別エントリー履歴
- [x] エントリー統計

## 9. 目標管理機能

### 9.1 目標設定
- [x] 選手別目標設定
- [x] 大会別目標タイム設定
- [x] 質的・量的目標の設定
- [x] 目標期限の管理

### 9.2 マイルストーン管理
- [x] 目標達成のためのマイルストーン設定
- [x] マイルストーンの進捗管理
- [x] マイルストーンのレビュー機能

### 9.3 目標分析
- [x] 目標達成率の確認
- [x] 目標と実績の比較
- [x] 目標設定の履歴

## 10. お知らせ管理機能

### 10.1 お知らせ配信
- [x] お知らせの作成・編集・削除
- [x] お知らせの公開・非公開管理
- [x] お知らせの一覧表示
- [x] お知らせの詳細表示

### 10.2 お知らせ配信管理
- [x] お知らせの公開日時設定
- [x] お知らせの重要度管理
- [x] お知らせの配信履歴

## 11. 追加要件（ヒアリング項目）

### 11.1 機能追加の検討項目
- [ ] 選手の健康管理機能
- [ ] 栄養管理・食事記録機能
- [ ] 怪我・体調不良の記録機能
- [ ] 選手の心理状態記録機能
- [ ] 保護者向け機能（選手の状況確認）
- [ ] チーム間の交流機能
- [ ] 動画分析機能
- [ ] データエクスポート機能
- [ ] レポート生成機能
- [ ] 通知機能（メール・プッシュ通知）

### 11.2 UI/UX改善項目
- [ ] モバイル対応の強化
- [ ] ダッシュボードの改善
- [ ] グラフ・チャート機能の追加
- [ ] 検索・フィルター機能の強化
- [ ] データ可視化の改善

### 11.3 システム改善項目
- [ ] パフォーマンス最適化
- [ ] セキュリティ強化
- [ ] バックアップ機能の強化
- [ ] API機能の拡張
- [ ] 外部システム連携

## 12. 技術要件

### 12.1 使用技術
- **フレームワーク**: Ruby on Rails 8.0
- **データベース**: PostgreSQL
- **認証**: Devise
- **フロントエンド**: Tailwind CSS, Stimulus
- **ファイル管理**: Active Storage
- **API**: RESTful API

### 12.2 セキュリティ要件
- [x] パスワードの複雑性チェック
- [x] セッション管理
- [x] CSRF対策
- [x] SQLインジェクション対策
- [x] XSS対策

## 13. Rails開発ベストプラクティス

### 13.1 コード品質・設計原則

#### 13.1.1 設計原則
- **DRY (Don't Repeat Yourself)**: 重複コードの排除
- **SOLID原則**: 単一責任、開放閉鎖、リスコフ置換、インターフェース分離、依存性逆転
- **KISS (Keep It Simple, Stupid)**: シンプルな設計を心がける
- **YAGNI (You Aren't Gonna Need It)**: 必要になるまで実装しない

#### 13.1.2 命名規則
- **モデル**: 単数形、キャメルケース（例: `User`, `PracticeLog`）
- **コントローラー**: 複数形、キャメルケース（例: `UsersController`, `PracticeLogsController`）
- **ビュー**: スネークケース（例: `index.html.erb`, `show.html.erb`）
- **メソッド**: スネークケース（例: `create_user`, `update_practice_log`）
- **定数**: 大文字、アンダースコア（例: `MAX_RECORDS`, `DEFAULT_PAGE_SIZE`）

### 13.2 モデル層のベストプラクティス

#### 13.2.1 モデル設計
- **アソシエーション**: 適切な関連付けを定義
- **バリデーション**: データ整合性の確保
- **コールバック**: 必要最小限の使用
- **スコープ**: よく使うクエリの定義
- **enum**: 状態管理の活用

```ruby
# 良い例
class User < ApplicationRecord
  has_one :user_auth, dependent: :destroy
  has_many :records, dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 255 }
  validates :generation, presence: true, numericality: { greater_than: 0 }
  
  enum user_type: { player: 0, manager: 1, coach: 2, director: 3 }
  
  scope :active, -> { where(active: true) }
  scope :by_generation, ->(gen) { where(generation: gen) }
  
  def admin?
    %w[coach director manager].include?(user_type)
  end
end
```

#### 13.2.2 データベース設計
- **インデックス**: 検索頻度の高いカラムに設定
- **制約**: データベースレベルでの整合性確保
- **マイグレーション**: 段階的な変更管理
- **シードデータ**: 開発・テスト用データの管理

### 13.3 コントローラー層のベストプラクティス

#### 13.3.1 コントローラー設計
- **単一責任**: 1つのコントローラーに1つの責任
- **スキニーコントローラー**: ビジネスロジックはモデルに委譲
- **Strong Parameters**: セキュリティの確保
- **before_action**: 共通処理の抽出

```ruby
# 良い例
class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :check_permissions, only: [:create, :update, :destroy]

  def index
    @users = User.includes(:user_auth).order(:generation, :name)
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to admin_users_path, notice: 'ユーザーを作成しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :generation, :user_type, :gender, :birthday)
  end
end
```

#### 13.3.2 エラーハンドリング
- **適切なHTTPステータスコード**: レスポンスの明確化
- **例外処理**: 予期しないエラーの適切な処理
- **ログ出力**: デバッグ情報の記録

### 13.4 ビュー層のベストプラクティス

#### 13.4.1 ビュー設計
- **パーシャル**: 再利用可能なコンポーネントの作成
- **ヘルパー**: ビュー専用のロジックの分離
- **フォーム**: 適切なバリデーション表示
- **レスポンシブデザイン**: モバイル対応

```erb
<!-- 良い例 -->
<%= form_with(model: @user, local: true) do |form| %>
  <div class="form-group">
    <%= form.label :name, class: "form-label" %>
    <%= form.text_field :name, class: "form-input #{'error' if @user.errors[:name].any?}" %>
    <% if @user.errors[:name].any? %>
      <div class="error-message"><%= @user.errors[:name].join(', ') %></div>
    <% end %>
  </div>
<% end %>
```

#### 13.4.2 アセット管理
- **CSS**: Tailwind CSSの活用
- **JavaScript**: Stimulusコントローラーの使用
- **画像**: Active Storageの活用

### 13.5 API設計のベストプラクティス

#### 13.5.1 RESTful API
- **HTTPメソッド**: 適切なメソッドの使用
- **URL設計**: リソース指向の設計
- **レスポンス形式**: 一貫したJSON形式
- **バージョニング**: APIバージョンの管理

```ruby
# 良い例
class Api::V1::UsersController < Api::V1::BaseController
  def index
    users = User.includes(:user_auth).order(:name)
    render_success({
      users: users.map { |user| user_serializer(user) }
    })
  end

  def show
    user = User.find(params[:id])
    render_success({ user: user_serializer(user) })
  rescue ActiveRecord::RecordNotFound
    render_error("ユーザーが見つかりません", :not_found)
  end

  private

  def user_serializer(user)
    {
      id: user.id,
      name: user.name,
      user_type: user.user_type,
      email: user.user_auth&.email
    }
  end
end
```

### 13.6 テストのベストプラクティス

#### 13.6.1 テスト戦略
- **単体テスト**: モデル、ヘルパー、サービスクラス
- **統合テスト**: コントローラー、ビュー
- **システムテスト**: エンドツーエンドの動作確認
- **ファクトリー**: テストデータの管理

```ruby
# 良い例
RSpec.describe User, type: :model do
  describe 'バリデーション' do
    it '名前が必須であること' do
      user = build(:user, name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("を入力してください")
    end
  end

  describe 'メソッド' do
    it '管理者かどうかを判定できること' do
      coach = build(:user, :coach)
      player = build(:user, :player)
      
      expect(coach.admin?).to be true
      expect(player.admin?).to be false
    end
  end
end
```

### 13.7 セキュリティのベストプラクティス

#### 13.7.1 認証・認可
- **Devise**: 認証機能の活用
- **権限管理**: 適切なアクセス制御
- **セッション管理**: セキュアなセッション処理
- **CSRF対策**: トークンの適切な使用

#### 13.7.2 データ保護
- **Strong Parameters**: パラメータの制限
- **SQLインジェクション対策**: プリペアドステートメントの使用
- **XSS対策**: エスケープ処理の徹底
- **ファイルアップロード**: 適切な検証

### 13.8 パフォーマンスのベストプラクティス

#### 13.8.1 データベース最適化
- **N+1問題の回避**: includes, preload, eager_loadの活用
- **インデックス**: 適切なインデックスの設定
- **クエリ最適化**: 不要なクエリの削減
- **ページネーション**: 大量データの適切な処理

```ruby
# 良い例（N+1問題の回避）
users = User.includes(:user_auth, :records).where(generation: 1)

# 悪い例（N+1問題が発生）
users = User.where(generation: 1)
users.each { |user| user.user_auth.email } # 追加クエリが発生
```

#### 13.8.2 キャッシュ戦略
- **フラグメントキャッシュ**: 部分的なキャッシュ
- **ページキャッシュ**: 静的ページのキャッシュ
- **Redis**: セッション・キャッシュの管理

### 13.9 開発環境のベストプラクティス

#### 13.9.1 開発ツール
- **RuboCop**: コードスタイルの統一
- **Brakeman**: セキュリティチェック
- **RSpec**: テストフレームワーク
- **FactoryBot**: テストデータの管理

#### 13.9.2 環境管理
- **環境変数**: 機密情報の適切な管理
- **Docker**: 開発環境の統一
- **Git**: バージョン管理の徹底

### 13.10 デプロイメントのベストプラクティス

#### 13.10.1 本番環境
- **環境変数**: 本番用設定の管理
- **ログ管理**: 適切なログ出力
- **監視**: システム監視の設定
- **バックアップ**: データの定期バックアップ

#### 13.10.2 CI/CD
- **自動テスト**: プルリクエスト時の自動テスト
- **コードレビュー**: 品質確保のためのレビュー
- **自動デプロイ**: 安全なデプロイメント

### 13.11 コードレビューのチェックポイント

#### 13.11.1 機能面
- [ ] 要件を満たしているか
- [ ] エラーハンドリングが適切か
- [ ] セキュリティ上の問題はないか
- [ ] パフォーマンスに問題はないか

#### 13.11.2 コード品質
- [ ] 可読性が高いか
- [ ] 適切な命名がされているか
- [ ] 重複コードがないか
- [ ] テストが十分か

#### 13.11.3 Rails慣例
- [ ] Railsの慣例に従っているか
- [ ] 適切なディレクトリ構造か
- [ ] 適切なファイル名か
- [ ] 適切なメソッド名か

## 14. 運用要件

### 14.1 パフォーマンス要件
- ページ読み込み時間: 3秒以内
- 同時接続数: 100ユーザー
- データベース応答時間: 1秒以内

### 14.2 可用性要件
- システム稼働率: 99.5%以上
- バックアップ: 日次
- 障害復旧時間: 4時間以内

## 15. 今後の開発計画

### 15.1 短期計画（1-3ヶ月）
1. 既存機能のバグ修正・改善
2. UI/UXの改善
3. モバイル対応の強化

### 15.2 中期計画（3-6ヶ月）
1. 追加機能の実装（健康管理、栄養管理など）
2. データ分析機能の強化
3. 通知機能の実装

### 15.3 長期計画（6ヶ月以上）
1. AI機能の導入
2. 外部システムとの連携
3. スケーラビリティの向上

---

**作成日**: 2025年1月
**更新日**: 2025年1月
**作成者**: 開発チーム 