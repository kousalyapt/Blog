Rails.application.routes.draw do

  devise_for :users

  root "articles#index"

  resources :articles do
    resources :comments
  end

  get "/archived_articles", to: "articles#archive"

  get 'users/google_oauth2', to: 'users#google_oauth2'
  get 'users/google_oauth2/callback', to: 'users#google_oauth2_callback'

  get 'users/linkedin', to: 'users#linkedin'
  get 'users/linkedin/callback', to: 'users#linkedin_callback'

  get 'users/github', to: 'users#github'
  get 'users/github/callback', to: 'users#github_callback'

  
end
