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

  end
end
