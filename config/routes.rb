Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'pages#home'

  resources :marc, only: [:index] do
    collection do
      get 'sync'
    end
  end
end
