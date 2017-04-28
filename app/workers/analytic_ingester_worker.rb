require 'faraday'

class AnalyticIngesterWorker
  @queue = :analytic_ingester

  def self.perform(fastfile_id, error, crash, launches, timestamp_seconds, versions={})
    @logger = create_logger

    start = Time.now

    analytics = []

    if fastfile_id.present? && launches.size == 1 && launches['fastlane']
      completion_status = crash.present? ? 'crash' : ( error.present? ? 'error' : 'success' )
      analytics << event_for_web_onboarding(fastfile_id, completion_status, timestamp_seconds)
    end

    launches.each do |action, count|
      action_version = versions[action] || 'unknown'
      action_completion_status = action == crash ? 'crash' : ( action == error ? 'error' : 'success' )

      analytics << event_for_completion(action, action_completion_status, action_version, timestamp_seconds)
      analytics << event_for_count(action, count, action_version, timestamp_seconds)
    end

    analytic_event_body = { analytics: analytics }.to_json

    @logger.info "Sending analytic event: #{analytic_event_body}"

    response = Faraday.new(:url => ENV["ANALYTIC_INGESTER_URL"]).post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = analytic_event_body
    end

    stop = Time.now

    @logger.info "Analytic ingester response was: #{response.status}"
    @logger.info "Sending analytic ingester event took #{(stop - start) * 1000}ms"
  end

  def self.event_for_web_onboarding(fastfile_id, completion_status, timestamp_seconds)
    {
      event_source: {
        oauth_app_name: 'fastlane-enhancer',
        product: 'fastlane_web_onboarding'
      },
      actor: {
        name: 'customer',
        detail: fastfile_id
      },
      action: {
        name: 'fastfile_executed'
      },
      primary_target: {
        name: 'fastlane_completion_status',
        detail: completion_status
      },
      millis_since_epoch: timestamp_seconds * 1000,
      version: 1
    }
  end

  def self.event_for_completion(action, completion_status, version, timestamp_seconds)
    {
      event_source: {
        oauth_app_name: 'fastlane-enhancer',
        product: 'fastlane'
      },
      actor: {
        name: 'action',
        detail: action
      },
      action: {
        name: 'execution_completed'
      },
      primary_target: {
        name: 'completion_status',
        detail: completion_status
      },
      secondary_target: {
        name: 'version',
        detail: version
      },
      millis_since_epoch: timestamp_seconds * 1000,
      version: 1
    }
  end

  def self.event_for_count(action, count, version, timestamp_seconds)
    {
      event_source: {
        oauth_app_name: 'fastlane-enhancer',
        product: 'fastlane'
      },
      actor: {
        name: 'action',
        detail: action
      },
      action: {
        name: 'execution_counted'
      },
      primary_target: {
        name: 'count',
        detail: count.to_s || "1"
      },
      secondary_target: {
        name: 'version',
        detail: version
      },
      millis_since_epoch: timestamp_seconds * 1000,
      version: 1
    }
  end

  def self.create_logger
    if ENV['USE_LOGSTASH']
      LogStashLogger.new(type: :file, path: "#{Rails.root}/log/#{@queue}_worker_#{Rails.env}.log", sync: true)
    else
      Logger.new(STDOUT)
    end
  end
end
