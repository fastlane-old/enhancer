class BaconsController < ApplicationController
  def did_launch
    launches = JSON.parse(params[:steps]) rescue nil
    unless launches
      render json: { error: "Missing values" }
      return
    end

    # Store the number of runs per action
    now = Time.now.to_date
    launches.each do |action, count|
      entry = Bacon.where(action_name: action, launch_date: now).take
      entry ||= Bacon.create!(action_name: action, launch_date: now, launches: 0, number_errors: 0)

      entry.launches += count
      entry.save
    end

    # Store the error information
    error_name = params[:error]
    if error_name
      b = Bacon.where(action_name: error_name, launch_date: now).take
      if b
        b.number_errors += 1
        b.save
      end
    end

    render json: { success: true }
  end

  def stats
    actions = Bacon.all.collect { |b| b.action_name }.uniq
    @sums = []
    actions.each do |action|
      entry = {
        action: action,
        launches: Bacon.where(action_name: action).sum(:launches),
        errors: Bacon.where(action_name: action).sum(:number_errors)
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
  end

  def ran
    Random.rand(255)
  end

  def graphs
    @data = {}
    @days = []
    start_time = Time.at(1428883200) # the first day

    Bacon.all.order(:launch_date).each do |bacon|
      random_color = "rgba(#{ran}, #{ran}, #{ran}, 1.0)"
      @data[bacon.action_name] ||= {
        label: bacon.action_name,
        fillColor: "rgba(220,220,220,0.2)",
        strokeColor: random_color,
        pointColor: random_color,
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(220,220,220,1)",
        data: []
      }

      counter = (bacon.launch_date.to_date - start_time.to_date).to_i

      @data[bacon.action_name][:data][counter] ||= 0
      @data[bacon.action_name][:data][counter] += bacon.launches

      # Fill nils with 0
      @data[bacon.action_name][:data].each_with_index do |k, index|
        @data[bacon.action_name][:data][index] ||= 0
      end

      formatted_string = bacon.launch_date.strftime("%d.%m.%Y")
      @days << formatted_string unless @days.include?formatted_string
    end

    # Sort by # of launches
    @data = @data.sort_by { |name, data| data[:data].sum }.reverse

    # Now generate cumulative graph
    @cumulative = []
    @data.each do |key, current|
      new_val = current.dup
      new_data = []
      new_val[:data].each_with_index do |value, i|
        new_data[i] = value + (new_data[-1] || 0)
      end
      new_val[:data] = new_data
      @cumulative << new_val
    end
  end
end
