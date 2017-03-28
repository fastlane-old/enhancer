require 'faraday'

class AnalyticIngesterWorker
  include Sidekiq::Worker

  def perform(fastfile_id, error, crash)
    start = Time.now

    completion_status =  crash ? 'crash' : ( error ? 'error' : 'success')
    analytic_event_body = {
      analytics: [{
        event_source: {
          oauth_app_name: 'fastlane-enhancer',
          product: 'fastlane_web_onboarding'
        },
        actor: {
          name:'customer',
          detail: fastfile_id
        },
        action: {
          name: 'fastfile_executed'
        },
        primary_target: {
          name: 'fastlane_completion_status',
          detail: completion_status
        },
        millis_since_epoch: Time.now.to_i * 1000,
        version: 1
      }]
    }.to_json

    puts "Sending analytic event: #{analytic_event_body}"

    Faraday.new(:url => ENV["ANALYTIC_INGESTER_URL"]).post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = analytic_event_body
    end

    stop = Time.now
    puts "Sending analytic ingester event took #{(stop - start) * 1000}ms"
  end
end
