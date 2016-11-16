require 'faraday'

class BaconsController < ApplicationController
  before_filter :authenticate, only: [:graphs, :stats]

  def did_launch
    launches = JSON.parse(params[:steps]) rescue nil

    unless launches
      render json: { error: "Missing values" }
      return
    end

    # Store the number of runs per action
    now = Time.now.to_date
    launches.each do |action, count|
      entry = Bacon.find_or_create_by(action_name: action, launch_date: now, tool_version: tool_version(action))
      entry.increment(:launches, count)
      entry.save
    end

    if params[:error]
      update_bacon_for(params[:error], now) do |bacon|
        bacon.increment(:number_errors)
        bacon.save
      end
    end

    if params[:crash]
      update_bacon_for(params[:crash], now) do |bacon|
        bacon.increment(:number_crashes)
        bacon.save
      end
    end

    # Only report analytic ingester events for fastlane tool launches
    if launches.size == 1 && launches['fastlane']
      send_analytic_ingester_event(params[:fastfile_id], params[:error], params[:crash])
    end

    render json: { success: true }
  end

  # This helps us track the success/failure of Fastfiles which are generated
  # by an automated process, such as fastlane web onboarding
  def send_analytic_ingester_event(fastfile_id, error, crash)
    return unless ENV['ANALYTIC_INGESTER_URL'].present? && fastfile_id.present?

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
  end

  def update_bacon_for(action_name, launch_date)
    version = tool_version(action_name)
    Bacon.find_by(action_name: action_name, launch_date: launch_date, tool_version: version).try do |bacon|
      yield bacon
    end
  end

  def stats
    launches = Bacon.group(:action_name).sum(:launches)
    number_errors = Bacon.group(:action_name).sum(:number_errors)

    @sums = []
    launches.each do |action, _|
      entry = {
        action: action,
        launches: launches[action],
        errors: number_errors[action],
      }
      entry[:ratio] = (entry[:errors].to_f / entry[:launches].to_f).round(3)
      @sums << entry
    end

    @sums.sort! { |a, b| b[:ratio] <=> a[:ratio] }

    @by_launches = @sums.sort { |a, b| b[:launches] <=> a[:launches] }

    @levels = [
      { value: 0.5, color: 'red' },
      { value: 0.3, color: 'orange' },
      { value: 0.1, color: 'yellow' },
      { value: 0.0, color: 'green' }
    ]

    respond_to do |format|
      format.html # renders the matching template
      format.json { render json: @by_launches }
    end
  end

  def tool_version(name)
    versions[name] || 'unknown'
  end

  def versions
    @versions ||= JSON.parse(params[:versions]) rescue {}
  end
end
