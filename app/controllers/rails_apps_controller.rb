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
        # Create new Rails app
        Rails.logger.info("Creating new Rails app: #{app_name}")
        system("rails new #{app_name}")

        # Navigate into the app directory
        Dir.chdir(app_name) do
          # Initialize Git repository and commit the initial state
          Rails.logger.info('Initializing Git repository and committing initial state')
          system('git init')
          system('git add .')
          system('git commit -m "Initial commit"')

          # Create GitHub repository and push
          # This assumes you've set GITHUB_PAT as an environment variable in Heroku
          github_token = ENV['ACCESS_PAT']
          Rails.logger.info("Creating GitHub repository and pushing to it")
          system("curl -H 'Authorization: token #{github_token}' https://api.github.com/user/repos -d '{\"name\":\"#{app_name}\"}'")
          system("git remote add origin https://github.com/Romazd/#{app_name}.git")
          system('git push -u origin master')
        end
      end
    end

    render json: { message: "Rails app creation initiated for: #{app_name}" }
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end
end
