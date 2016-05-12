class ApplicationController < ActionController::Base
  TOOLS = %w(
    cert
    credentials_manager
    deliver
    fastlane
    fastlane_core
    frameit
    gym
    match
    pem
    pilot
    produce
    scan
    screengrab
    sigh
    snapshot
    spaceship
    supply
    watchbuild
  )

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == "admin" && password == ENV["FL_PASSWORD"]
    end
  end
end
