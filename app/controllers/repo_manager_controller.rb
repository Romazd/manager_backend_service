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
    # access_token = ENV['ACCESS_PAT']
    access_token = Rails.application.credentials.dig(:github_access, :pat)
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
  
  def remove_repo_collaborator
    repo_name = params[:repo_name]
    username_to_remove = params[:username_to_remove]
    Rails.logger.info("Removing #{username_to_remove} from #{repo_name}")
    # access_token = ENV['ACCESS_PAT']
    access_token = Rails.application.credentials.dig(:github_access, :pat)
    uri = URI("https://api.github.com/repos/Romazd/#{repo_name}/collaborators/#{username_to_remove}")
    request = Net::HTTP::Delete.new(uri)
    request["Authorization"] = "token #{access_token}"
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
  
    Rails.logger.info("Response: #{response}")
    if response.is_a?(Net::HTTPSuccess)
      text_response = "#{username_to_remove.capitalize} was successfully removed from #{repo_name}"
      Rails.logger.info(text_response)
      
      render json: { remove_response: text_response }
    else
      render json: { error: 'Failed to add a collaborator' }, status: :bad_request
    end
  rescue => e
    puts "Error removing collaborator: #{e.message}"
    false
  end

  def create_webhook
    repo_name = params[:repo_name]
    access_token = Rails.application.credentials.dig(:github_access, :pat)
    webhook_url = params[:webhook_url]
    events = params[:events] || ['push']
    uri = URI("https://api.github.com/repos/Romazd/#{repo_name}/hooks")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = {
      "Authorization" => "token #{access_token}",
      "Accept" => "application/vnd.github.v3+json",
      "Content-Type" => "application/json"
    }
    binding.pry
    body = {
      name: "web",
      active: true,
      events: events,
      config: {
        url: webhook_url,
        content_type: "json"
      }
    }.to_json

    response = http.post(uri, body, headers)
    if response.is_a?(Net::HTTPSuccess)
      binding.pry
      render json: { remove_response: response }
    else
      render json: { error: 'Failed to add a webhook' }, status: :bad_request
    end
  rescue => e
    puts "Failed to create webhook: #{e.message}"
    false
  end

  def webhook_receiver
    binding.pry
  end

  def protect_branch
    repo_name = params[:repo_name]
    branch = params[:branch]
    access_token = Rails.application.credentials.dig(:github_access, :pat)
    uri = URI("https://api.github.com/repos/Romazd/#{repo_name}/branches/#{branch}/protection")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
  
    protection_rules = {
      required_status_checks: nil,
      enforce_admins: true,
      required_pull_request_reviews: {
        required_approving_review_count: 1
      },
      restrictions: nil,
      allow_force_pushes: false,
      allow_deletions: false
    }
  
    request = Net::HTTP::Put.new(uri)
    request["Authorization"] = "token #{access_token}"
    request["Accept"] = "application/vnd.github.v3+json"
    request["Content-Type"] = "application/json"
    request.body = protection_rules.to_json
  
    response = http.request(request)
  
    if response.is_a?(Net::HTTPSuccess)
      binding.pry
      Rails.logger.info(response.body)
      puts "Branch protection applied successfully!"
    else
      puts "Failed to apply branch protection: #{response.body}"
    end
  rescue => e
    puts "Error: #{e.message}"
  end

  def create_workflow_webhook
    repo_name = params[:repo_name]
    access_token = Rails.application.credentials.dig(:github_access, :pat)
    webhook_url = params[:webhook_url]
    uri = URI("https://api.github.com/repos/Romazd/#{repo_name}/hooks")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    headers = {
      "Authorization" => "token #{access_token}",
      "Accept" => "application/vnd.github+json",
      "Content-Type" => "application/json"
    }
    
    body = {
      name: "web",
      active: true,
      events: ["workflow_run"],
      config: {
        url: webhook_url,
        content_type: "json",
      }
    }.to_json
  
    response = http.post(uri.path, body, headers)
  
    puts response.code
    puts response.body
  end
  

end
