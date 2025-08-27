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
      resources :races, only: [:index, :show]
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
      
      # 練習記録
      resources :practice, only: [:index, :show] do
        member do
          get 'practice_times', to: 'practice#practice_times'
        end
      end
      
      # 管理者機能
      namespace :admin do
        get 'dashboard', to: 'dashboard#index'
        get '', to: 'dashboard#index' # admin/のルートもダッシュボードに
      end
      
      # ユーザー管理
      namespace :admin do
        resources :users do
          collection do
            post 'import/preview', to: 'users#import_preview'
            post 'import/execute', to: 'users#import_execute'
            get 'import/template', to: 'users#import_template'
          end
        end
      end
      
      # お知らせ管理
      namespace :admin do
        resources :announcements do
          member do
            patch 'toggle_active', to: 'announcements#toggle_active'
          end
          collection do
            post 'bulk_action', to: 'announcements#bulk_action'
            get 'statistics', to: 'announcements#statistics'
          end
        end
      end
      
      # スケジュール管理
      namespace :admin do
        resources :schedules, except: [:new, :edit] do
          collection do
            post 'import/preview', to: 'schedules#import_preview'
            post 'import/execute', to: 'schedules#import_execute'
            get 'import/template', to: 'schedules#import_template'
          end
        end
      end
      
      # 大会管理
      namespace :admin do
        resources :competitions, only: [:index, :show] do
          member do
            patch 'entry_status', to: 'competitions#update_entry_status'
            get 'result', to: 'competitions#result'
            post 'save_results', to: 'competitions#save_results'
          end
          collection do
            post 'entry/start', to: 'competitions#start_entry_collection'
          end
        end
        get 'competitions/:competition_id/entries', to: 'competitions#show_entries'
      end

      # 出欠管理
      namespace :admin do
        resources :attendances, only: [:index] do
          collection do
            get 'check', to: 'attendances#check'
            patch 'check', to: 'attendances#update_check'
            post 'save_check', to: 'attendances#save_check'
            get 'status', to: 'attendances#status'
            patch 'status', to: 'attendances#update_status'
          end
        end
      end

      # 目標管理
      namespace :admin do
        resources :objectives do
          member do
            post 'milestones', to: 'objectives#create_milestone'
          end
          collection do
            get 'dashboard', to: 'objectives#dashboard'
          end
        end
        
        # マイルストーン管理
        patch 'objectives/milestones/:milestone_id', to: 'objectives#update_milestone'
        delete 'objectives/milestones/:milestone_id', to: 'objectives#destroy_milestone'
        post 'objectives/milestones/:milestone_id/review', to: 'objectives#create_milestone_review'
      end
      
      # 練習管理
      namespace :admin do
        resources :practices do
          collection do
            get 'time_setup', to: 'practices#time_setup'
            post 'time_preview', to: 'practices#time_preview'
            post 'time_save', to: 'practices#time_save'
            post 'attendees', to: 'practices#manage_attendees'
            get 'attendees_list', to: 'practices#attendees_list'
            get 'register_setup', to: 'practices#register_setup'
            post 'register', to: 'practices#create_register'
          end
        end
      end
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
  get "races", to: "races#index", as: :races
  
  # エントリー提出・削除・取得
  post "races/entry", to: "races#submit_entry", as: "submit_entry"
  delete "races/entry/:id", to: "races#delete_entry", as: "delete_entry"
  get "races/current_entries/:competition_id", to: "races#get_current_entries", as: "get_current_entries"

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
  get "admin", to: "admin/base#index", as: :admin

  # [管理者]ユーザー管理
  get "admin/users", to: "admin/users#index", as: "admin_users"
  get "admin/users/new", to: "admin/users#create", as: "admin_create_user"
  post "admin/users", to: "admin/users#create"
  patch "admin/users", to: "admin/users#create"
  get "admin/users/import", to: "admin/users#import", as: "admin_users_import"
  get "admin/users/import/template", to: "admin/users#import_template", as: "admin_users_import_template"
  post "admin/users/import/preview", to: "admin/users#import_preview", as: "admin_users_import_preview"
  post "admin/users/import/execute", to: "admin/users#import_execute", as: "admin_users_import_execute"
  get "admin/users/:id", to: "admin/users#show", as: "admin_user"
  get "admin/users/:id/edit", to: "admin/users#edit", as: "admin_edit_user"
  patch "admin/users/:id", to: "admin/users#update", as: "admin_update_user"
  delete "admin/users/:id", to: "admin/users#destroy", as: "admin_destroy_user"

  # [管理者]目標管理
  get "admin/objective", to: "admin/objectives#index", as: "admin_objective"

  # [管理者]お知らせ管理
  delete "admin/announcement/:id", to: "admin/announcements#destroy", as: "admin_destroy_announcement"
  patch "admin/announcement/:id", to: "admin/announcements#update", as: "admin_update_announcement"
  get "admin/announcement", to: "admin/announcements#index", as: "admin_announcement"
  post "admin/announcement", to: "admin/announcements#create"

  # [管理者]スケジュール管理
  get "admin/schedule", to: "admin/schedules#index", as: "admin_schedule"
  post "admin/schedule", to: "admin/schedules#create", as: "admin_create_schedule"
  get "admin/schedule/import", to: "admin/schedules#import", as: "admin_schedule_import"
  get "admin/schedule/import/template", to: "admin/schedules#import_template", as: "admin_schedule_import_template"
  post "admin/schedule/import/preview", to: "admin/schedules#import_preview", as: "admin_schedule_import_preview"
  post "admin/schedule/import/execute", to: "admin/schedules#import_execute", as: "admin_schedule_import_execute"
  get "admin/schedule/:id/edit", to: "admin/schedules#edit", as: "admin_edit_schedule"
  patch "admin/schedule/:id", to: "admin/schedules#update", as: "admin_update_schedule"
  delete "admin/schedule/:id", to: "admin/schedules#destroy", as: "admin_destroy_schedule"

  # [管理者]練習管理
  get "admin/practice", to: "admin/practices#index", as: "admin_practice"
  get "admin/practice/time", to: "admin/practices#time", as: "admin_practice_time"
  post "admin/practice/time", to: "admin/practices#time", as: "admin_practice_time_preview"
  get "admin/practice/time/input", to: "admin/practices#time_input", as: "admin_practice_time_input"
  post "admin/practice/time/input/add_attendee", to: "admin/practices#add_attendee", as: "admin_practice_add_attendee"
  delete "admin/practice/time/input/remove_attendee", to: "admin/practices#remove_attendee", as: "admin_practice_remove_attendee"
  post "admin/practice/time/save", to: "admin/practices#create_time", as: "admin_create_practice_log_and_times"
  get "admin/practice/register", to: "admin/practices#register", as: "admin_practice_register"
  post "admin/practice_register", to: "admin/practices#create_register", as: "admin_practice_register_create"
  get "admin/practice/:id", to: "admin/practices#show", as: "admin_practice_show"
  get "admin/practice/:id/edit", to: "admin/practices#edit", as: "admin_practice_edit"
  patch "admin/practice/:id", to: "admin/practices#update", as: "admin_practice_update"
  delete "admin/practice/:id", to: "admin/practices#destroy", as: "admin_practice_destroy"

  # [管理者]出欠管理
  get "admin/attendance", to: "admin/attendances#index", as: "admin_attendance"
  get "admin/attendance/check", to: "admin/attendances#check", as: "admin_attendance_check"
  patch "admin/attendance/check", to: "admin/attendances#update_check", as: "update_admin_attendance_check"
  patch "admin/attendance/save", to: "admin/attendances#save_check", as: "save_admin_attendance_check"
  get "admin/attendance/status", to: "admin/attendances#status", as: "admin_attendance_status"
  patch "admin/attendance/status", to: "admin/attendances#update_status", as: "update_admin_attendance_status"

  # [管理者]出席状況更新
  get "admin/attendance/update", to: "admin/attendances#update", as: "admin_attendance_update"
  patch "admin/attendance/update", to: "admin/attendances#save_update", as: "save_admin_attendance_update"

  # [管理者]大会管理
  post "admin/competition/entry/start", to: "admin/competitions#start_entry_collection", as: "admin_start_entry_collection"
  get "admin/competition/entry/:competition_id", to: "admin/competitions#show_entries", as: "admin_show_entries"
  get "admin/competition/result/:id", to: "admin/competitions#result", as: "admin_competition_result"
  patch "admin/competition/:id/entry_status", to: "admin/competitions#update_entry_status", as: "admin_update_competition_entry_status"
  patch "admin/competition/:id/save_results", to: "admin/competitions#save_results", as: "admin_competition_save_results"
  get "admin/competition", to: "admin/competitions#index", as: "admin_competition"

  # エラーページ
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  match "/422", to: "errors#unprocessable_entity", via: :all

  # 存在しないURLへのアクセスを404ページにリダイレクト
  match "*path", to: "errors#not_found", via: :all

  post "calendar/update", to: "calendar#update"
end
