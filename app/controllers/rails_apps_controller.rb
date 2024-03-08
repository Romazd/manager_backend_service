class RailsAppsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    app_name = params[:app_name]

    if app_name.blank?
      render json: { error: 'App name is required' }, status: :bad_request
      return
    end

    # Logic to create Rails app and setup GitHub repo will go here

    render json: { message: "Rails app creation initiated for: #{app_name}" }
  end
end
