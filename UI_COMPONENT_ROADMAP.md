# UIコンポーネント統一化ロードマップ

## 全画面一覧

### 1. 認証・ランディング画面
- **ランディングページ** (`app/views/landing/index.html.erb`)
  - システム紹介ページ
  - 機能説明、料金プラン、ログインリンク

### 2. 認証関連画面（Devise）※スキップ対象
- **ログイン画面** (`app/views/devise/sessions/new.html.erb`)
- **新規登録画面** (`app/views/devise/registrations/new.html.erb`)
- **パスワードリセット画面** (`app/views/devise/passwords/new.html.erb`)
- **メール確認画面** (`app/views/devise/confirmations/new.html.erb`)
- **アカウント編集画面** (`app/views/devise/registrations/edit.html.erb`)

### 3. メイン機能画面
- **ホーム画面** (`app/views/home/index.html.erb`)
  - ダッシュボード、お知らせ、カレンダー、ベストタイム表示
- **マイページ** (`app/views/mypage/index.html.erb`)
  - プロフィール表示・編集、自己紹介
- **メンバー一覧** (`app/views/member/index.html.erb`)
  - 選手一覧、世代別表示
- **練習記録** (`app/views/practice/index.html.erb`)
  - 練習ログ、タイム記録
- **レース管理** (`app/views/races/index.html.erb`)
  - 大会記録、エントリー管理
- **目標管理** (`app/views/objective/index.html.erb`)
  - 目標設定、マイルストーン管理
- **出欠管理** (`app/views/attendance/index.html.erb`)
  - 出席状況確認・編集

### 4. 管理者画面
- **管理者ダッシュボード** (`app/views/admin/base/index.html.erb`)
- **ユーザー管理** (`app/views/admin/users/`)
  - 一覧 (`index.html.erb`)
  - 新規作成 (`create.html.erb`)
  - 編集 (`edit.html.erb`)
  - インポート (`import.html.erb`)
- **お知らせ管理** (`app/views/admin/announcements/`)
  - 一覧 (`index.html.erb`)
- **スケジュール管理** (`app/views/admin/schedules/`)
  - 一覧 (`index.html.erb`)
  - インポート (`import.html.erb`)
- **練習管理** (`app/views/admin/practices/`)
  - 一覧 (`index.html.erb`)
  - タイム入力 (`time.html.erb`)
  - 登録 (`register.html.erb`)
  - 詳細 (`show.html.erb`)
  - 編集 (`edit.html.erb`)
- **出欠管理** (`app/views/admin/attendances/`)
  - 一覧 (`index.html.erb`)
  - チェック (`check.html.erb`)
  - ステータス (`status.html.erb`)
  - 更新 (`update.html.erb`)
- **大会管理** (`app/views/admin/competitions/`)
  - 一覧 (`index.html.erb`)
  - 結果 (`result.html.erb`)
- **目標管理** (`app/views/admin/objectives/`)
  - 一覧 (`index.html.erb`)

### 5. 共有コンポーネント
- **サイドバー** (`app/views/shared/_sidebar.html.erb`)
- **ヘッダー** (`app/views/shared/_header.html.erb`)
- **カレンダー** (`app/views/shared/_calendar.html.erb`)
- **モーダル** (`app/views/shared/_modal.html.erb`)
- **イベント出席状況** (`app/views/shared/_event_attendance_status.html.erb`)

### 6. エラー画面
- **404エラー** (`app/views/errors/not_found.html.erb`)
- **500エラー** (`app/views/errors/internal_server_error.html.erb`)
- **422エラー** (`app/views/errors/unprocessable_entity.html.erb`)

### 7. ページネーション
- **Kaminari** (`app/views/kaminari/`)
  - ページネーションコンポーネント群

## 現状分析

### 問題点
1. **一貫性のないスペーシング**: 各ページで異なるpadding/margin値を使用
2. **重複するスタイル**: 同じようなUIパターンが複数箇所で重複定義
3. **レスポンシブ対応の不統一**: モバイル対応がページによって異なる
4. **コンポーネント化の不足**: 再利用可能なコンポーネントが少ない

### 現在の使用パターン
- `pt-8`, `mb-12`, `p-6` などが散在
- `rounded-2xl`, `rounded-xl`, `rounded-lg` の混在
- `shadow-xl`, `shadow-lg`, `shadow-sm` の不統一
- カラーシステムの一貫性不足

## フェーズ1: 基盤コンポーネントの作成（1-2週間）

### 1.1 レイアウトコンポーネント
```erb
<!-- app/views/shared/components/_page_container.html.erb -->
<div class="w-full pt-8">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <%= yield %>
  </div>
</div>
```

```erb
<!-- app/views/shared/components/_section.html.erb -->
<div class="mb-8">
  <%= yield %>
</div>
```

### 1.2 カードコンポーネント
```erb
<!-- app/views/shared/components/_card.html.erb -->
<div class="bg-white rounded-xl shadow-lg overflow-hidden">
  <div class="p-6">
    <%= yield %>
  </div>
</div>
```

### 1.3 ヘッダーコンポーネント
```erb
<!-- app/views/shared/components/_page_header.html.erb -->
<div class="text-center mb-8">
  <h1 class="text-3xl font-bold text-gray-900 mb-2"><%= title %></h1>
  <% if subtitle.present? %>
    <p class="text-lg text-gray-600"><%= subtitle %></p>
  <% end %>
</div>
```

## フェーズ2: 機能別コンポーネントの作成（2-3週間）

### 2.1 データ表示コンポーネント
- テーブルコンポーネント
- リストコンポーネント
- 統計カードコンポーネント

### 2.2 フォームコンポーネント
- 入力フィールドコンポーネント
- ボタンコンポーネント
- セレクトボックスコンポーネント

### 2.3 通知コンポーネント
- アラートコンポーネント
- トーストコンポーネント
- ローディングコンポーネント

## フェーズ3: ページ別リファクタリング（3-4週間）

### 3.1 優先度A（高）
1. **ホームページ** (`app/views/home/index.html.erb`)
   - お知らせセクションのコンポーネント化
   - ベストタイムテーブルのコンポーネント化
   - カレンダーセクションの統一

2. **管理者ダッシュボード** (`app/views/admin/base/index.html.erb`)
   - 管理カードのコンポーネント化
   - グリッドレイアウトの統一

3. **目標管理** (`app/views/objective/index.html.erb`)
   - 目標カードのコンポーネント化
   - 進捗表示の統一

### 3.2 優先度B（中）
1. **レース管理** (`app/views/races/index.html.erb`)
   - エントリーカードのコンポーネント化
   - 記録テーブルの統一

2. **マイページ** (`app/views/mypage/index.html.erb`)
   - プロフィールカードのコンポーネント化
   - 編集フォームの統一

3. **メンバー管理** (`app/views/member/index.html.erb`)
   - 選手カードのコンポーネント化
   - 世代別表示の統一

4. **練習管理** (`app/views/practice/index.html.erb`)
   - 練習ログカードのコンポーネント化
   - タイム入力フォームの統一

5. **出欠管理** (`app/views/attendance/index.html.erb`)
   - 出席状況カードのコンポーネント化
   - 編集フォームの統一

### 3.3 優先度C（低）
1. **管理者画面群**
   - **ユーザー管理** (`app/views/admin/users/`)
     - 一覧テーブルのコンポーネント化
     - フォームの統一
   - **お知らせ管理** (`app/views/admin/announcements/`)
     - お知らせカードのコンポーネント化
   - **スケジュール管理** (`app/views/admin/schedules/`)
     - スケジュールカードのコンポーネント化
   - **練習管理** (`app/views/admin/practices/`)
     - 練習管理カードのコンポーネント化
   - **出欠管理** (`app/views/admin/attendances/`)
     - 出席管理カードのコンポーネント化
   - **大会管理** (`app/views/admin/competitions/`)
     - 大会カードのコンポーネント化
   - **目標管理** (`app/views/admin/objectives/`)
     - 目標管理カードのコンポーネント化

2. **認証関連画面** (`app/views/devise/`) ※スキップ対象
   - ログインフォームの統一
   - 新規登録フォームの統一
   - パスワードリセットフォームの統一

3. **エラー画面** (`app/views/errors/`)
   - エラーページの統一デザイン

4. **ランディングページ** (`app/views/landing/index.html.erb`)
   - セクション別コンポーネント化
   - レスポンシブ対応の統一

## フェーズ4: デザインシステムの確立（1-2週間）

### 4.1 カラーシステム
```css
/* app/assets/stylesheets/components/_colors.css */
:root {
  --primary-blue: #1e40af;
  --primary-blue-light: #3b82f6;
  --success-green: #059669;
  --warning-yellow: #d97706;
  --error-red: #dc2626;
  --gray-50: #f9fafb;
  --gray-100: #f3f4f6;
  --gray-200: #e5e7eb;
  --gray-300: #d1d5db;
  --gray-400: #9ca3af;
  --gray-500: #6b7280;
  --gray-600: #4b5563;
  --gray-700: #374151;
  --gray-800: #1f2937;
  --gray-900: #111827;
}
```

### 4.2 スペーシングシステム
```css
/* app/assets/stylesheets/components/_spacing.css */
:root {
  --space-xs: 0.25rem;   /* 4px */
  --space-sm: 0.5rem;    /* 8px */
  --space-md: 1rem;      /* 16px */
  --space-lg: 1.5rem;    /* 24px */
  --space-xl: 2rem;      /* 32px */
  --space-2xl: 3rem;     /* 48px */
  --space-3xl: 4rem;     /* 64px */
}
```

### 4.3 タイポグラフィシステム
```css
/* app/assets/stylesheets/components/_typography.css */
:root {
  --font-size-xs: 0.75rem;   /* 12px */
  --font-size-sm: 0.875rem;  /* 14px */
  --font-size-base: 1rem;    /* 16px */
  --font-size-lg: 1.125rem;  /* 18px */
  --font-size-xl: 1.25rem;   /* 20px */
  --font-size-2xl: 1.5rem;   /* 24px */
  --font-size-3xl: 1.875rem; /* 30px */
  --font-size-4xl: 2.25rem;  /* 36px */
}
```

## フェーズ5: レスポンシブ対応の統一（1週間）

### 5.1 ブレークポイントの統一
```css
/* app/assets/stylesheets/components/_breakpoints.css */
:root {
  --breakpoint-sm: 640px;
  --breakpoint-md: 768px;
  --breakpoint-lg: 1024px;
  --breakpoint-xl: 1280px;
  --breakpoint-2xl: 1536px;
}
```

### 5.2 モバイルファーストの実装
- すべてのコンポーネントでモバイルファーストアプローチ
- タッチフレンドリーなインターフェース
- 適切なタップターゲットサイズ

## 実装ガイドライン

### コンポーネント作成ルール
1. **単一責任**: 1つのコンポーネントに1つの責任
2. **再利用性**: 複数の場所で使用可能
3. **カスタマイズ性**: パラメータで動作を変更可能
4. **アクセシビリティ**: WCAG準拠
5. **パフォーマンス**: 軽量で高速

### 命名規則
- コンポーネント: `_component_name.html.erb`
- CSSクラス: `component-name`
- JavaScript: `component_name_controller.js`

### ファイル構造
```
app/views/shared/components/
├── layout/
│   ├── _page_container.html.erb
│   ├── _section.html.erb
│   ├── _grid.html.erb
│   └── _page_header.html.erb
├── cards/
│   ├── _info_card.html.erb
│   ├── _stats_card.html.erb
│   ├── _action_card.html.erb
│   ├── _profile_card.html.erb
│   ├── _announcement_card.html.erb
│   ├── _objective_card.html.erb
│   ├── _practice_card.html.erb
│   ├── _race_card.html.erb
│   └── _attendance_card.html.erb
├── forms/
│   ├── _input_field.html.erb
│   ├── _button.html.erb
│   ├── _select.html.erb
│   ├── _form_group.html.erb
│   └── _form_actions.html.erb
├── data/
│   ├── _table.html.erb
│   ├── _list.html.erb
│   ├── _chart.html.erb
│   ├── _best_times_table.html.erb
│   ├── _entries_table.html.erb
│   └── _attendance_table.html.erb
├── feedback/
│   ├── _alert.html.erb
│   ├── _toast.html.erb
│   ├── _loading.html.erb
│   └── _empty_state.html.erb
├── navigation/
│   ├── _breadcrumb.html.erb
│   ├── _pagination.html.erb
│   └── _tabs.html.erb
└── specific/
    ├── _calendar_widget.html.erb
    ├── _time_input.html.erb
    ├── _progress_bar.html.erb
    └── _status_badge.html.erb
```

## テスト戦略

### 1. ビジュアルテスト
- 各コンポーネントの見た目の一貫性確認
- レスポンシブ対応の確認
- ブラウザ互換性の確認

### 2. アクセシビリティテスト
- スクリーンリーダー対応
- キーボードナビゲーション
- カラーコントラスト

### 3. パフォーマンステスト
- ページ読み込み速度
- コンポーネント描画速度
- メモリ使用量

## 成功指標

### 定量的指標
- コード重複率: 50%削減
- ページ読み込み速度: 20%改善
- コンポーネント再利用率: 80%以上

### 定性的指標
- 開発者体験の向上
- デザイン一貫性の向上
- メンテナンス性の向上

## リスク管理

### 技術的リスク
- **既存機能への影響**: 段階的移行でリスク最小化
- **パフォーマンス劣化**: 継続的な監視と最適化
- **ブラウザ互換性**: テスト環境での事前確認

### スケジュールリスク
- **開発時間の見積もり**: バッファ時間の確保
- **優先度の変更**: 柔軟なスケジュール調整
- **リソース不足**: 段階的実装で対応

## 実装スケジュール詳細

### フェーズ1: 基盤コンポーネントの作成（1-2週間）

#### 週1: レイアウト・カードコンポーネント
- [ ] `_page_container.html.erb` - ページコンテナ
- [ ] `_section.html.erb` - セクションコンテナ
- [ ] `_page_header.html.erb` - ページヘッダー
- [ ] `_info_card.html.erb` - 情報カード
- [ ] `_stats_card.html.erb` - 統計カード
- [ ] `_action_card.html.erb` - アクションカード

#### 週2: フォーム・データコンポーネント
- [ ] `_input_field.html.erb` - 入力フィールド
- [ ] `_button.html.erb` - ボタン
- [ ] `_select.html.erb` - セレクトボックス
- [ ] `_table.html.erb` - テーブル
- [ ] `_list.html.erb` - リスト
- [ ] `_alert.html.erb` - アラート

### フェーズ2: 機能別コンポーネントの作成（2-3週間）

#### 週3: 特定機能コンポーネント
- [ ] `_profile_card.html.erb` - プロフィールカード
- [ ] `_announcement_card.html.erb` - お知らせカード
- [ ] `_objective_card.html.erb` - 目標カード
- [ ] `_best_times_table.html.erb` - ベストタイムテーブル
- [ ] `_entries_table.html.erb` - エントリーテーブル

#### 週4: 管理機能コンポーネント
- [ ] `_practice_card.html.erb` - 練習カード
- [ ] `_race_card.html.erb` - レースカード
- [ ] `_attendance_card.html.erb` - 出席カード
- [ ] `_calendar_widget.html.erb` - カレンダーウィジェット
- [ ] `_time_input.html.erb` - タイム入力

#### 週5: ナビゲーション・フィードバック
- [ ] `_breadcrumb.html.erb` - パンくずリスト
- [ ] `_pagination.html.erb` - ページネーション
- [ ] `_tabs.html.erb` - タブ
- [ ] `_loading.html.erb` - ローディング
- [ ] `_empty_state.html.erb` - 空状態

### フェーズ3: ページ別リファクタリング（3-4週間）

#### 週6-7: 優先度Aページ
- [ ] ホームページ (`app/views/home/index.html.erb`)
- [ ] 管理者ダッシュボード (`app/views/admin/base/index.html.erb`)
- [ ] 目標管理 (`app/views/objective/index.html.erb`)

#### 週8-9: 優先度Bページ
- [ ] レース管理 (`app/views/races/index.html.erb`)
- [ ] マイページ (`app/views/mypage/index.html.erb`)
- [ ] メンバー管理 (`app/views/member/index.html.erb`)
- [ ] 練習管理 (`app/views/practice/index.html.erb`)
- [ ] 出欠管理 (`app/views/attendance/index.html.erb`)

#### 週10-11: 優先度Cページ
- [ ] 管理者画面群 (`app/views/admin/`)
- [ ] エラー画面 (`app/views/errors/`)
- [ ] ランディングページ (`app/views/landing/index.html.erb`)

### フェーズ4: デザインシステムの確立（1-2週間）

#### 週12: CSS変数・ユーティリティ
- [ ] カラーシステム (`_colors.css`)
- [ ] スペーシングシステム (`_spacing.css`)
- [ ] タイポグラフィシステム (`_typography.css`)

#### 週13: レスポンシブ対応
- [ ] ブレークポイント統一 (`_breakpoints.css`)
- [ ] モバイルファースト実装
- [ ] タッチフレンドリー対応

### フェーズ5: テスト・最適化（1週間）

#### 週14: テスト・最適化
- [ ] ビジュアルテスト
- [ ] アクセシビリティテスト
- [ ] パフォーマンステスト
- [ ] ブラウザ互換性テスト

## スキップ対象の理由

### 認証関連画面（Devise）をスキップする理由
1. **Deviseの標準デザイン**: Deviseは既に統一されたデザインシステムを提供
2. **セキュリティの重要性**: 認証画面の変更はセキュリティリスクを伴う
3. **開発効率**: 認証画面のカスタマイズは工数が大きい
4. **優先度**: メイン機能のUI統一を優先すべき

## 次のステップ

1. **フェーズ1の開始**: 基盤コンポーネントの作成
2. **チーム内での合意**: デザインシステムの確認
3. **開発環境の準備**: コンポーネントライブラリの構築
4. **テスト環境の整備**: 自動テストの実装

---

**作成日**: 2025年1月
**更新予定**: 各フェーズ完了時
**責任者**: 開発チーム
