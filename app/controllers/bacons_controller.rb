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
    parsed_versions = JSON.parse(params[:versions]) rescue {}
    Resque.enqueue(BaconUpdaterWorker, launches, params[:error], params[:crash], parsed_versions)

    send_analytic_ingester_event(params[:fastfile_id], params[:error], params[:crash], launches, Time.now.to_i)

    render json: { success: true }
  end

  # This helps us track the success/failure of Fastfiles which are generated
  # by an automated process, such as fastlane web onboarding
  def send_analytic_ingester_event(fastfile_id, error, crash, launches, timestamp_seconds)
    return unless ENV['ANALYTIC_INGESTER_URL'].present?

    Resque.enqueue(AnalyticIngesterWorker, fastfile_id, error, crash, launches, timestamp_seconds)
  end

  def stats
    bacon_actions = Bacon.group(:action_name)

    if params[:only]
      only_show = params[:only].is_a?(Array) ? params[:only] : [params[:only]]
      bacon_actions = bacon_actions.where(action_name: only_show)
    end

    if params[:weeks]
      num_weeks = params[:weeks].to_i
      cutoff_date = num_weeks.weeks.ago

      bacon_actions = bacon_actions.where("launch_date >= :cutoff_date", cutoff_date: cutoff_date)
    end

    @minimum_launches = 20000
    if params[:minimum_launches].to_s.length > 0 # because 0 is also a valid number
      @minimum_launches = params[:minimum_launches].to_i
    elsif params[:weeks].to_i > 0
      @minimum_launches = params[:weeks].to_i * 100
    end

    # Selects the sums and action name without converting into a Bacon object
    launch_info = bacon_actions.pluck("sum(number_errors)", "sum(launches)", "sum(number_crashes)", :action_name)

    @sums = []
    launch_info.each do |errors, launches, crashes, action|
      next if launches < @minimum_launches
      entry = {
        action: action,
        action_short: action.gsub("fastlane-plugin-", "plugin-").truncate(50),
        launches: launches,
        errors: errors,
        ratio: (errors.to_f / launches.to_f).round(3),
        crashes: crashes
      }
      ratio_above = params[:ratio_above].nil? ? 0.0 : params[:ratio_above].to_f
      ratio_below = params[:ratio_below].nil? ? 1.0 : params[:ratio_below].to_f
      @sums << entry if entry[:ratio] >= ratio_above && entry[:ratio] <= ratio_below
    end

    @sums.sort! { |a, b| b[:ratio] <=> a[:ratio] }

    @by_launches = @sums.sort { |a, b| b[:launches] <=> a[:launches] }
    # Add the ranking number as one of the values per hash
    @by_launches.each_with_index { |value, index| value[:index] = index + 1 }

    if params[:top]
      top_percentage = params[:top].to_i / 100.0
      @sums = @sums.first(top_percentage * @sums.count)
      @by_launches = @by_launches.first(top_percentage * @by_launches.count)
    end

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
end
