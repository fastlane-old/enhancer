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

    @summary = select_summary_info(@tool)
    @details = select_details_info(@tool).group_by(&:launch_date)
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

  def select_summary_info(tool)
    select_statement = [
      "action_name",
      "SUM(launches) as sum_launches",
      "(SUM(number_errors) - SUM(number_crashes)) as sum_user_errors",
      "SUM(number_crashes) as sum_crashes",
      "(1::float - (SUM(number_errors)::float / SUM(launches)::float)) * 100::float as success_rate",
      "((SUM(number_errors)::float - SUM(number_crashes)::float) / SUM(launches)::float) * 100::float as user_error_rate",
      "(SUM(number_crashes)::float / SUM(launches)::float) * 100::float as crash_rate"
    ].join(', ')

    Bacon.select(select_statement).
      where("tool_version <> 'unknown' AND action_name = ?", tool).
      group("action_name").
      order("action_name ASC").
      first
  end

  def select_details_info(tool)
    date_limit = 7.days.ago.to_date

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
