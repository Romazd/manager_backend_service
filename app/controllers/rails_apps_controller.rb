require 'tmpdir'

class RailsAppsController < ApplicationController

  def create
    app_name = params[:app_name]

    if app_name.blank?
      render json: { error: 'App name is required' }, status: :bad_request
      return
    end
  
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Rails.logger.info("Creating new Rails app: #{app_name}")
        system("rails new #{app_name}")
  
        Dir.chdir(app_name) do
          Rails.logger.info('Initializing Git repository and committing initial state')
          system('git init')
          system('git config user.email "segundo.marco@gmail.com"')
          system('git config user.name "Marco Sandoval"')
          system('git add .')
          system('git commit -m "Initial commit"')
  
          github_token = ENV['ACCESS_PAT']
          github_username = 'Romazd'
          repo_name = "#{app_name}"
          Rails.logger.info("Creating GitHub repository and pushing to it")
          system("curl -X POST -H 'Authorization: token #{github_token}' -H 'Content-Type: application/json' https://api.github.com/user/repos -d '{\"name\":\"#{app_name}\"}'")
          system("git remote add origin https://#{github_username}:#{github_token}@github.com/#{github_username}/#{repo_name}.git")
          system('git branch -M main') # Ensure the branch is named 'main'
          system('git push -u origin main') # Push using the correct branch name
        end
      end
    end
  
    render json: { message: "Rails app creation initiated for: #{app_name}" }
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end
  
end
