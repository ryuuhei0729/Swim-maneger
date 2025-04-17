Rails.application.routes.draw do
  devise_for :user_auths, controllers: {
    sessions: 'user_auths/sessions'
  }
  devise_scope :user_auth do
    root to: 'user_auths/sessions#new'
  end
  
  get 'home', to: 'home#index', as: :home
  get 'mypage', to: 'mypage#index', as: :mypage
  
  get 'member', to: 'member#index', as: :member
end