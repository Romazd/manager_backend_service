Rails.application.routes.draw do
  get 'rails_apps/create'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  post '/create_rails_app', to: 'rails_apps#create'

  post "/list_user_repos", to: "repo_manager#list_user_repos"

  post "/add_repo_collaborator", to: "repo_manager#add_repo_collaborator"

  post "/remove_repo_collaborator", to: "repo_manager#remove_repo_collaborator"

  # Defines the root path route ("/")
  # root "posts#index"
end
