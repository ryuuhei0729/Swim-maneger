Rails.application.routes.draw do
  # ルートパス
  devise_scope :user_auth do
    root to: 'user_auths/sessions#new'
  end

  # 認証関連
  devise_for :user_auths, controllers: {
    sessions: 'user_auths/sessions'
  }

  # 全員見れるページ
  get 'home', to: 'home#index', as: :home
  get 'mypage', to: 'mypage#index', as: :mypage
  patch 'mypage', to: 'mypage#update'
  get 'member', to: 'member#index', as: :member

  # 管理者のみのページ
  get 'admin', to: 'admin#index', as: :admin
  get 'admin/index'
  
  # [管理者]新規登録
  get 'admin/create_user', to: 'admin#create_user', as: 'admin_create_user'
  post 'admin/users', to: 'admin#create_user', as: 'admin_users'
  patch 'admin/users', to: 'admin#create_user'
  
  # [管理者]お知らせ管理
  delete 'admin/announcement/:id', to: 'admin#destroy_announcement', as: 'admin_destroy_announcement'
  patch 'admin/announcement/:id', to: 'admin#update_announcement', as: 'admin_update_announcement'
  get 'admin/announcement', to: 'admin#announcement', as: 'admin_announcement'
  post 'admin/announcement', to: 'admin#create_announcement'

  # エラーページ
  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
  match '/422', to: 'errors#unprocessable_entity', via: :all

  # 存在しないURLへのアクセスを404ページにリダイレクト
  match '*path', to: 'errors#not_found', via: :all
end