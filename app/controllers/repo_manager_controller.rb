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
    Rails.logger.info("Response: #{response.body}")
    repos = JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
    repos.map { |repo| repo['name'] }
    Rails.logger.info("Repos: #{repos}")
    "hello"
  rescue => e
    puts "Error: #{e.message}"
    []
  end
  

end
