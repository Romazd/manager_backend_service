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
  
  

end
