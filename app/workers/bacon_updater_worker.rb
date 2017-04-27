class BaconUpdaterWorker
  @queue = :bacon_updater

  ActiveRecord::Base.logger = Logger.new(STDOUT)

  def self.perform(launches, error, crash, versions={})
    puts "Starting bacons update for launches: #{launches}, versions: #{versions}, error: #{error}, crash: #{crash}"

    start = Time.now
    # Returns any connections in use by the current thread back to the pool, and also returns
    # connections to the pool cached by threads that are no longer alive.
    ActiveRecord::Base.clear_active_connections!
    stop = Time.now
    puts "Timing: ActiveRecord::Base.clear_active_connections! took #{(stop - start) * 1000}ms"

    start = Time.now
    now = start.to_date
    launches.each do |action, count|
      tool_version = versions[action] || 'unknown'
      entry = Bacon.find_or_create_by(action_name: action, launch_date: now, tool_version: tool_version)
      entry.increment(:launches, count)
      entry.save
    end

    if error.present?
      tool_version = versions[error] || 'unknown'
      update_bacon_for(error, now, tool_version) do |bacon|
        bacon.increment(:number_errors)
        bacon.save
      end
    end

    if crash.present?
      tool_version = versions[crash] || 'unknown'
      update_bacon_for(crash, now, tool_version) do |bacon|
        bacon.increment(:number_crashes)
        bacon.save
      end
    end
    stop = Time.now
    puts "Timing: Bacon DB writes took #{(stop - start) * 1000}ms"

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
