Rails.application.routes.draw do
  # ルートパス
  root to: "landing#index"

  # API ルーティング
  namespace :api do
    namespace :v1 do
      get '/', to: 'landing#index'
      resources :auth, only: [] do
        collection do
          post 'login'
          delete 'logout'
        end
      end
      resources :members, only: [:index]
      resources :records, only: [:index, :show]
      resources :attendance, only: [] do
        collection do
          get '/', to: 'attendance#show'
          patch '/', to: 'attendance#update'
          get 'event_status/:event_id', to: 'attendance#event_status'
        end
      end
      get 'calendar', to: 'calendar#show'
      post 'calendar/update', to: 'calendar#update'
      get 'home', to: 'home#index'
      get 'mypage', to: 'mypage#show'
      patch 'mypage', to: 'mypage#update'
      resources :objectives, only: [:index, :show, :create, :update, :destroy], controller: 'objective'
      
      # 管理者機能
      get 'admin', to: 'admin#index'
      
      # ユーザー管理
      get 'admin/users', to: 'admin#users'
      post 'admin/users', to: 'admin#create_user'
      
      # お知らせ管理
      get 'admin/announcements', to: 'admin#announcements'
      post 'admin/announcements', to: 'admin#create_announcement'
      patch 'admin/announcements/:id', to: 'admin#update_announcement'
      delete 'admin/announcements/:id', to: 'admin#destroy_announcement'
      
      # スケジュール管理
      get 'admin/schedules', to: 'admin#schedules'
      post 'admin/schedules', to: 'admin#create_schedule'
      patch 'admin/schedules/:id', to: 'admin#update_schedule'
      delete 'admin/schedules/:id', to: 'admin#destroy_schedule'
      get 'admin/schedules/:id', to: 'admin#show_schedule'
      
      # 目標管理
      get 'admin/objectives', to: 'admin#objectives'
      
      # 練習管理
      get 'admin/practices', to: 'admin#practices'
      get 'admin/practice_time_setup', to: 'admin#practice_time_setup'
      post 'admin/practice_time_preview', to: 'admin#practice_time_preview'
      post 'admin/practice_logs', to: 'admin#create_practice_log_and_times'
      get 'admin/practice_register_setup', to: 'admin#practice_register_setup'
      post 'admin/practice_register', to: 'admin#create_practice_register'
    end
  end

  # 認証関連
  devise_for :user_auths, controllers: {
    sessions: "user_auths/sessions"
  }

  # Active Storageのルート
  scope "/rails/active_storage" do
    get "/blobs/redirect/:signed_id/*filename" => "active_storage/blobs/redirect#show"
    get "/representations/redirect/:signed_blob_id/:variation_key/*filename" => "active_storage/representations/redirect#show"
    get "/blobs/proxy/:signed_id/*filename" => "active_storage/blobs/proxy#show"
    get "/representations/proxy/:signed_blob_id/:variation_key/*filename" => "active_storage/representations/proxy#show"
    get "/blobs/:signed_id/*filename" => "active_storage/blobs/redirect#show"
    get "/representations/:signed_blob_id/:variation_key/*filename" => "active_storage/representations/redirect#show"
    get "/disk/:encoded_key/*filename" => "active_storage/disk#show"
  end

  # 全員見れるページ
  get "home", to: "home#index", as: :home
  get "mypage", to: "mypage#index", as: :mypage
  patch "mypage", to: "mypage#update"
  get "member", to: "member#index", as: :member
  get "practice", to: "practice#index", as: :practice
  get "records", to: "records#index", as: :records
  
  # エントリー提出
  post "records/entry", to: "records#submit_entry", as: "submit_entry"

  # 目標管理
  get "objective", to: "objective#index", as: :objective_index
  get "objective/new", to: "objective#new", as: :new_objective
  post "objective", to: "objective#create", as: :objective

  # 出席管理
  get "attendance", to: "attendance#index", as: :attendance
  get "attendance/edit", to: "attendance#edit", as: :edit_attendance
  patch "attendance", to: "attendance#update", as: :update_attendance_edit
  post "attendance/save_individual", to: "attendance#save_individual", as: :save_individual_attendance
  post "attendance/update", to: "attendance#update_attendance", as: :update_attendance
  get "attendance/event_status/:event_id", to: "attendance#event_status", as: :event_status

  # 練習記録
  get "practice/practice_times/:id", to: "practice#practice_times"

  # イベント管理
  resources :events do
    member do
      patch :update_attendance
    end
  end

  # 管理者のみのページ
  get "admin", to: "admin#index", as: :admin
  get "admin/index"

  # [管理者]新規登録
  get "admin/create_user", to: "admin#create_user", as: "admin_create_user"
  post "admin/users", to: "admin#create_user", as: "admin_users"
  patch "admin/users", to: "admin#create_user"

  # [管理者]目標管理
  get "admin/objective", to: "admin#objective", as: "admin_objective"

  # [管理者]お知らせ管理
  delete "admin/announcement/:id", to: "admin#destroy_announcement", as: "admin_destroy_announcement"
  patch "admin/announcement/:id", to: "admin#update_announcement", as: "admin_update_announcement"
  get "admin/announcement", to: "admin#announcement", as: "admin_announcement"
  post "admin/announcement", to: "admin#create_announcement"

  # [管理者]スケジュール管理
  get "admin/schedule", to: "admin#schedule", as: "admin_schedule"
  post "admin/schedule", to: "admin#create_schedule", as: "admin_create_schedule"
  get "admin/schedule/import", to: "admin#schedule_import", as: "admin_schedule_import"
  get "admin/schedule/import/template", to: "admin#schedule_import_template", as: "admin_schedule_import_template"
  post "admin/schedule/import/preview", to: "admin#schedule_import_preview", as: "admin_schedule_import_preview"
  post "admin/schedule/import/execute", to: "admin#schedule_import_execute", as: "admin_schedule_import_execute"
  get "admin/schedule/:id/edit", to: "admin#edit_schedule", as: "admin_edit_schedule"
  patch "admin/schedule/:id", to: "admin#update_schedule", as: "admin_update_schedule"
  delete "admin/schedule/:id", to: "admin#destroy_schedule", as: "admin_destroy_schedule"

  # [管理者]練習管理
  get "admin/practice", to: "admin#practice", as: "admin_practice"
  get "admin/practice/time", to: "admin#practice_time", as: "admin_practice_time"
  post "admin/practice/time", to: "admin#create_practice_log_and_times", as: "admin_create_practice_log_and_times"
  get "admin/practice/register", to: "admin#practice_register", as: "admin_practice_register"
  post "admin/practice_register", to: "admin#create_practice_register", as: "admin_practice_register_create"

  # [管理者]出欠管理
  get "admin/attendance", to: "admin#attendance", as: "admin_attendance"
  get "admin/attendance/check", to: "admin#attendance_check", as: "admin_attendance_check"
  patch "admin/attendance/check", to: "admin#update_attendance_check", as: "update_admin_attendance_check"
  patch "admin/attendance/save", to: "admin#save_attendance_check", as: "save_admin_attendance_check"

  # [管理者]出席状況更新
  get "admin/attendance/update", to: "admin#attendance_update", as: "admin_attendance_update"
  patch "admin/attendance/update", to: "admin#save_attendance_update", as: "save_admin_attendance_update"

  # [管理者]大会管理
  get "admin/competition", to: "admin#competition", as: "admin_competition"
  
  # [管理者]エントリー管理
  post "admin/competition/entry/start", to: "admin#start_entry_collection", as: "admin_start_entry_collection"
  get "admin/competition/entry/:event_id", to: "admin#show_entries", as: "admin_show_entries"

  # エラーページ
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  match "/422", to: "errors#unprocessable_entity", via: :all

  # 存在しないURLへのアクセスを404ページにリダイレクト
  match "*path", to: "errors#not_found", via: :all

  post "calendar/update", to: "calendar#update"
end
