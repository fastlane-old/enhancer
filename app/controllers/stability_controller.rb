class StabilityController < ApplicationController
  before_filter :authenticate

  def index
    @tool = params[:tool] || 'fastlane'
    @version = params[:version]

    all_names = select_all_names
    all_plugins = select_all_plugins
    @tool_select_groups = {
      'Tools' => TOOLS,
      'Actions' => all_names - TOOLS - all_plugins,
      'Plugins' => all_plugins
    }

    @details = select_details_info(@tool).group_by(&:launch_date)

    # Generate the data we need to show stability grouped by version, instead of date
    @graph_data = {}
    minimum_launches_to_show_in_graph = nil # we don't want to show the crash rate of a version that's only used once in the last month or so
    
    # Now detect the minimum launches we need to show a version
    @details.each do |_, bacon_list|
      bacon_list.each do |current_bacon|
        current_i = current_bacon.launches * 0.1

        if minimum_launches_to_show_in_graph.nil? || current_i > minimum_launches_to_show_in_graph
          minimum_launches_to_show_in_graph = current_i
        end
      end
    end

    @details.each do |_, bacon_list|
      bacon_list.each do |current_bacon|
        @graph_data[current_bacon[:tool_version]] ||= {
          number_user_errors: 0,
          number_crashes: 0,
          launches: 0
        }
        @graph_data[current_bacon[:tool_version]][:number_user_errors] += current_bacon.number_user_errors
        @graph_data[current_bacon[:tool_version]][:number_crashes] += current_bacon.number_crashes
        @graph_data[current_bacon[:tool_version]][:launches] += current_bacon.launches
      end
    end

    @graph_data = Hash[@graph_data.sort { |x, y| Gem::Version.new(x.first) <=> Gem::Version.new(y.first) }]

    highest_version = @graph_data.keys.last # to see releases that are being rolled out
    @graph_data.delete_if do |tool_version, data|
      data[:launches] < minimum_launches_to_show_in_graph && tool_version != highest_version
    end

    # @graph_data => {"1.105.3"=>{:number_user_errors=>1225, :number_crashes=>267, :launches => 123123},
    #                 "1.108.0"=>{:number_user_errors=>2195, :number_crashes=>430, :launches => 884743},
    #                 ...

    @versions = @graph_data.keys # needed for the graph
    @raw_graph = [
      {
        label: "Crashes",
        fillColor: "rgba(220,220,220,0.2)",
        backgroundColor: "rgba(220,220,220,0.07)",
        borderColor: "red",
        pointStrokeColor: "#fff",
        pointHitRadius: 10,
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(220,220,220,1)",
        data: @graph_data.collect do |_, a|
          (a[:number_crashes].to_f / a[:launches]).round(3) * 100
        end
      },
      {
        label: "User Errors",
        fillColor: "rgba(220,220,220,0.2)",
        backgroundColor: "rgba(220,220,220,0.07)",
        borderColor: "orange",
        pointStrokeColor: "#fff",
        pointHitRadius: 10,
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(220,220,220,1)",
        data: @graph_data.collect do |_, a|
          (a[:number_user_errors].to_f / a[:launches]).round(3) * 100
        end
      },
      {
        label: "Success",
        fillColor: "rgba(220,220,220,0.2)",
        backgroundColor: "rgba(220,220,220,0.07)",
        borderColor: "green",
        pointStrokeColor: "#fff",
        pointHitRadius: 10,
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(220,220,220,1)",
        data: @graph_data.collect do |_, a|
          ((a[:launches] - a[:number_user_errors] - a[:number_crashes]).to_f / a[:launches]).round(3) * 100
        end
      }
    ]
  end

  def select_all_names
    Bacon.where("tool_version <> 'unknown'").
      pluck(:action_name).
      map(&:downcase). # Unfortunately we have values like "FASTLANE" and 'Fastlane'
      uniq.
      sort
  end

  def select_all_plugins
    Bacon.where("action_name LIKE 'fastlane-plugin-%'").
      pluck(:action_name).
      map(&:downcase).
      uniq.
      sort
  end

  def select_details_info(tool)
    date_limit = 6.months.ago.to_date

    select_statement = [
      "action_name",
      "launch_date",
      "tool_version",
      "launches",
      "(number_errors - number_crashes) as number_user_errors",
      "number_crashes",
      "(1::float - (number_errors::float / launches::float)) * 100::float as success_rate",
      "((number_errors::float - number_crashes::float) / launches::float) * 100::float as user_error_rate",
      "(number_crashes::float / launches::float) * 100::float as crash_rate"
    ].join(', ')

    bacons = Bacon.select(select_statement).
      where("launch_date >= ?::date AND tool_version <> 'unknown' AND action_name = ?", date_limit, tool).
      order("launch_date DESC")

    bacons = bacons.where("tool_version = ?", params[:version]) if params[:version]

    bacons
  end
end
