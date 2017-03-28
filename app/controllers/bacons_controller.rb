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

    if params[:error].present?
      update_bacon_for(params[:error], now) do |bacon|
        bacon.increment(:number_errors)
        bacon.save
      end
    end

    if params[:crash].present?
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

    AnalyticIngesterWorker.perform_async(fastfile_id, error, crash)
  end

  def update_bacon_for(action_name, launch_date)
    version = tool_version(action_name)
    Bacon.find_by(action_name: action_name, launch_date: launch_date, tool_version: version).try do |bacon|
      yield bacon
    end
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

    # Selects the sums and action name without converting into a Bacon object
    launch_info = bacon_actions.pluck("sum(number_errors)", "sum(launches)", "sum(number_crashes)", :action_name)

    @sums = []
    launch_info.each do |errors, launches, crashes, action|
      entry = {
        action: action,
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

  def tool_version(name)
    versions[name] || 'unknown'
  end

  def versions
    @versions ||= JSON.parse(params[:versions]) rescue {}
  end
end
