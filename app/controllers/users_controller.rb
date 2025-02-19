require 'httparty'

class UsersController < ApplicationController

    def google_oauth2
      url = construct_google_url(ENV['GOOGLE_CLIENT_ID'], "http://localhost:3000/users/google_oauth2/callback", "email profile" )            
      redirect_to url, allow_other_host: true
    end
  
    def google_oauth2_callback
      response = request_google_token(params[:code])  
      if response.success?
        access_token = response.parsed_response['access_token']
        user_info_response = fetch_google_user_info(access_token)
        if user_info_response.success?
          create_or_sign_in_user(user_info_response.parsed_response)
        else
          redirect_to root_path, alert: "Failed to get user info."
        end
      else
        redirect_to root_path, alert: "Failed to authenticate with Google."
      end
    end

    def linkedin
      url = construct_linkedin_url(ENV['LINKEDIN_CLIENT_ID'], "http://localhost:3000/users/linkedin/callback", "r_liteprofile r_emailaddress"  )
      redirect_to url, allow_other_host: true
    end
  
    def linkedin_callback
      code = params[:code]
      response = request_linkedin_token(params[:code])
      if response.success?
        access_token = response.parsed_response['access_token']   
        profile_response, email_response = fetch_linkedin_user_info(access_token)
        if profile_response.success? && email_response.success?
          profile_info = profile_response.parsed_response
          email_info = email_response.parsed_response['elements'].first['handle~']['emailAddress']         
          create_or_sign_in_user(profile_info, email_info)
        else
          redirect_to root_path, alert: "Failed to retrieve LinkedIn profile information."
        end
      else
        redirect_to root_path, alert: "Failed to authenticate with LinkedIn."
      end
    end


    def github
      url = construct_github_url(ENV['GITHUB_CLIENT_ID'], "http://localhost:3000/users/github/callback" )      
      redirect_to url, allow_other_host: true
    end
  
    def github_callback
      response = request_github_token(params[:code])
      if response.success?
        access_token = response.parsed_response['access_token']    
        user_info_response, email_info_response = fetch_github_user_info(access_token)
        if user_info_response.success? && email_info_response.success?
          user_info = user_info_response.parsed_response
          email_info = email_info_response.parsed_response.find { |email| email['primary'] }['email']
          create_or_sign_in_user(user_info, email_info)
        else
          redirect_to root_path, alert: "Failed to retrieve GitHub profile information."
        end
      else
        redirect_to root_path, alert: "Failed to authenticate with GitHub."
      end
    end

    def construct_google_url( client_id, redirect_uri, scope )
        "https://accounts.google.com/o/oauth2/v2/auth?" \
            "client_id=#{client_id}&" \
            "redirect_uri=#{redirect_uri}&" \
            "response_type=code&" \
            "scope=#{scope}&" \
            "prompt=consent"
    end

    def construct_linkedin_url( client_id, redirect_uri, scope )
      "https://www.linkedin.com/oauth/v2/authorization?" \
                             "response_type=code&" \
                             "client_id=#{client_id}&" \
                              "redirect_uri=#{redirect_uri}&" \
                              "scope=#{scope}"
    end

    def construct_github_url(client_id, redirect_uri)
      "https://github.com/login/oauth/authorize?" \
                        "client_id=#{client_id}&" \
                        "redirect_uri=#{redirect_uri}&" \
                        "scope=user:email"
    end

    def request_google_token(code)
      HTTParty.post("https://oauth2.googleapis.com/token", {
        body: {
          code: code,
          client_id: ENV['GOOGLE_CLIENT_ID'],
          client_secret: ENV['GOOGLE_CLIENT_SECRET'],
          redirect_uri: "#{request.base_url}/users/google_oauth2/callback",
          grant_type: 'authorization_code'
        }
      })
    end

    def fetch_google_user_info(access_token)
      HTTParty.get("https://www.googleapis.com/oauth2/v3/userinfo", {
        headers: { 'Authorization' => "Bearer #{access_token}" }
      })
    end

    def create_or_sign_in_user(user_info, email = nil)
      email ||= user_info['email']
      name = user_info['name'] || "#{user_info['localizedFirstName']} #{user_info['localizedLastName']}"
      image_url = user_info['picture'] || user_info['avatar_url'] || user_info.dig('profilePicture', 'displayImage')
  
      @user = User.find_or_create_by(email: email) do |user|
        user.password = Devise.friendly_token[0, 20]
        user.name = name
        user.image_url = image_url
      end   
      sign_in_and_redirect @user, event: :authentication
    end

    def request_linkedin_token(code)
      HTTParty.post("https://www.linkedin.com/oauth/v2/accessToken", {
        body: {
          grant_type: 'authorization_code',
          code: code,
          redirect_uri: "#{request.base_url}/users/linkedin/callback",
          client_id: ENV['LINKEDIN_CLIENT_ID'],
          client_secret: ENV['LINKEDIN_CLIENT_SECRET']
        },
        headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
      })
    end

    def fetch_linkedin_user_info(access_token)
      profile_response = HTTParty.get("https://api.linkedin.com/v2/me", {
        headers: { 'Authorization' => "Bearer #{access_token}" }
      })
      
      email_response = HTTParty.get("https://api.linkedin.com/v2/emailAddress?q=members&projection=(elements*(handle~))", {
        headers: { 'Authorization' => "Bearer #{access_token}" }
      })
      
      [profile_response, email_response]
    end

    def request_github_token(code)
      HTTParty.post("https://github.com/login/oauth/access_token", {
        body: {
          client_id: ENV['GITHUB_CLIENT_ID'],
          client_secret: ENV['GITHUB_CLIENT_SECRET'],
          code: code,
          redirect_uri: "#{request.base_url}/users/github/callback"
        },
        headers: { 'Accept' => 'application/json' }
      })
    end

    def fetch_github_user_info(access_token)
      user_info_response = HTTParty.get("https://api.github.com/user", {
        headers: { 'Authorization' => "token #{access_token}" }
      })
      
      email_info_response = HTTParty.get("https://api.github.com/user/emails", {
        headers: { 'Authorization' => "token #{access_token}" }
      })
      
      [user_info_response, email_info_response]
    end

  end
  
  