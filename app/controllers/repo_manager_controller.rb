require 'net/http'
require 'uri'
require 'json'

class RepoManagerController < ApplicationController
  
  def list_user_repos
    access_token = ENV['ACCESS_PAT']
    uri = URI("https://api.github.com/users/Romazd/repos")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "token #{access_token}"
  
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
    
    if response.is_a?(Net::HTTPSuccess)
      repos = JSON.parse(response.body)
      repos_list = repos.map { |repo| repo['name'] }
      Rails.logger.info("User's repositories: #{repos_list.join(', ')}")
      
      render json: { repositories: repos_list }
    else
      render json: { error: 'Failed to fetch repositories' }, status: :bad_request
    end
  rescue => e
    Rails.logger.error "Error: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end

  def add_repo_collaborator
    repo_name = params[:repo_name]
    username_to_add = params[:username_to_add]
    permission = params[:permission] || 'push'
    access_token = ENV['ACCESS_PAT']
    uri = URI("https://api.github.com/repos/Romazd/#{repo_name}/collaborators/#{username_to_add}")
    request = Net::HTTP::Put.new(uri)
    request["Authorization"] = "token #{access_token}"
    request.body = {permission: permission}.to_json
  
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
    Rails.logger.info("Response: #{response}")
    if response.is_a?(Net::HTTPSuccess)
      add_response = JSON.parse(response.body)
      Rails.logger.info("Adding a collaborator was: #{add_response}")
      
      render json: { add_response: add_response }
    else
      render json: { error: 'Failed to add a collaborator' }, status: :bad_request
    end
  rescue => e
    puts "Error adding collaborator: #{e.message}"
    false
  end
  
  
  

end
