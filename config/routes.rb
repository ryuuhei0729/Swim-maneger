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
end