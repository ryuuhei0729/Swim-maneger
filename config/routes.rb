Rails.application.routes.draw do
  get "admin/index"
  devise_for :user_auths, controllers: {
    sessions: 'user_auths/sessions'
  }
  devise_scope :user_auth do
    root to: 'user_auths/sessions#new'
  end
  
  get 'home', to: 'home#index', as: :home
  get 'mypage', to: 'mypage#index', as: :mypage
  patch 'mypage', to: 'mypage#update'
  
  get 'member', to: 'member#index', as: :member
  get 'admin', to: 'admin#index', as: :admin
  get 'admin/create_user', to: 'admin#create_user', as: 'admin_create_user'
  post 'admin/users', to: 'admin#create_user', as: 'admin_users'
  patch 'admin/users', to: 'admin#create_user'
  
  # お知らせ管理機能のルーティング
  get 'admin/announcement', to: 'admin#announcement', as: 'admin_announcement'
  post 'admin/announcement', to: 'admin#create_announcement'
  patch 'admin/announcement/:id', to: 'admin#update_announcement', as: 'admin_update_announcement'
  delete 'admin/announcement/:id', to: 'admin#destroy_announcement', as: 'admin_destroy_announcement'
end