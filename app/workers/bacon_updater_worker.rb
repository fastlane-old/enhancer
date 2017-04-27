class BaconUpdaterWorker
  @queue = :bacon_updater

  ActiveRecord::Base.logger = Logger.new(STDOUT)

  def self.perform(launches, error, crash, versions={})
    puts "Starting bacons update for launches: #{launches}, versions: #{versions}, error: #{error}, crash: #{crash}"

    clear_start = Time.now
    # Returns any connections in use by the current thread back to the pool, and also returns
    # connections to the pool cached by threads that are no longer alive.
    ActiveRecord::Base.clear_active_connections!
    clear_stop = Time.now
    puts "Timing: ActiveRecord::Base.clear_active_connections! took #{(clear_stop - clear_start) * 1000}ms"

    now = Time.now.to_date

    launches_start = Time.now
    launches.each do |action, count|
      launch_start = Time.now

      tool_version = versions[action] || 'unknown'
      entry = Bacon.find_or_create_by(action_name: action, launch_date: now, tool_version: tool_version)
      entry.increment(:launches, count)
      entry.save

      launch_stop = Time.now
      puts "Timing: launch DB write took #{(launch_stop - launch_start) * 1000}ms"
    end
    launches_stop = Time.now
    puts "Timing: All launches DB writes took #{(launches_stop - launches_start) * 1000}ms"

    if error.present?
      error_start = Time.now

      tool_version = versions[error] || 'unknown'
      update_bacon_for(error, now, tool_version) do |bacon|
        bacon.increment(:number_errors)
        bacon.save
      end

      error_stop = Time.now
      puts "Timing: error DB write took #{(error_stop - error_start) * 1000}ms"
    end

    if crash.present?
      crash_start = Time.now

      tool_version = versions[crash] || 'unknown'
      update_bacon_for(crash, now, tool_version) do |bacon|
        bacon.increment(:number_crashes)
        bacon.save
      end

      crash_stop = Time.now
      puts "Timing: crash DB write took #{(crash_stop - crash_start) * 1000}ms"
    end

    puts "Finished bacons update for launches: #{launches}, versions: #{versions}, error: #{error}, crash: #{crash}"
  rescue => ex
    puts "#{ex.message} - #{ex.backtrace.join("\n")}"
  end

  def self.update_bacon_for(action_name, launch_date, tool_version)
    Bacon.find_by(action_name: action_name, launch_date: launch_date, tool_version: tool_version).try do |bacon|
      yield bacon
    end
  end
end
