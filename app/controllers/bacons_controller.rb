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

    values = []
    Bacon.all.order(:launch_date).each do |bacon|
      counter = (bacon.launch_date.to_date - start_time.to_date).to_i

      values[counter] ||= {launches: 0, errors: 0}
      values[counter][:launches] += bacon.launches
      values[counter][:errors] += bacon.number_errors

      formatted_string = bacon.launch_date.strftime("%d.%m.%Y")
      @days << formatted_string unless @days.include?formatted_string
    end

    # Fill nils with 0
    values.each_with_index do |k, index|
      puts k
      values[index] = (k[:errors].to_f / k[:launches].to_f * 100 rescue 0).round
    end

    @data[0] ||= {
      label: "Success Rate",
      fillColor: "rgba(220,220,220,0.2)",
      strokeColor: "rgba(220,220,220)",
      pointColor: "rgba(220,220,220)",
      pointStrokeColor: "#fff",
      pointHighlightFill: "#fff",
      pointHighlightStroke: "rgba(220,220,220,1)",
      data: values
    }
  end
end
