class BaconUpdaterWorker
  @queue = :bacon_updater

  ActiveRecord::Base.logger = Logger.new(STDOUT)

  def self.perform(launches, error, crash)
    puts "Starting bacons update for launches: #{launches}, error: #{error}, crash: #{crash}"

    # Returns any connections in use by the current thread back to the pool, and also returns
    # connections to the pool cached by threads that are no longer alive.
    ActiveRecord::Base.clear_active_connections!

    now = Time.now.to_date
    launches.each do |action, count|
      entry = Bacon.find_or_create_by(action_name: action, launch_date: now, tool_version: tool_version(action))
      entry.increment(:launches, count)
      entry.save
    end

    if error.present?
      update_bacon_for(error, now) do |bacon|
        bacon.increment(:number_errors)
        bacon.save
      end
    end

    if crash.present?
      update_bacon_for(crash, now) do |bacon|
        bacon.increment(:number_crashes)
        bacon.save
      end
    end

    puts "Finished bacons update for launches: #{launches}, error: #{error}, crash: #{crash}"
  end

  def self.update_bacon_for(action_name, launch_date)
    Bacon.find_by(action_name: action_name, launch_date: launch_date, tool_version: tool_version(action_name)).try do |bacon|
      yield bacon
    end
  end

  def self.tool_version(name)
    versions[name] || 'unknown'
  end

  def self.versions
    @versions ||= JSON.parse(params[:versions]) rescue {}
  end
end
