require 'sumologic'
require 'pp'
require 'terminal-table'
require 'sumo_result'
require 'sumo_aggregate_result'

class SearchRunner
  attr_reader :sumo

  def initialize(access_id:, access_key:)
    @sumo = SumoLogic::Client.new access_id, access_key, "https://api.eu.sumologic.com/api/v1/"
  end

  def run_query(query, from_time, to_time, time_zone)
    search_job = sumo.search_job(query, from_time, to_time, time_zone).body

    status = sumo.search_job_status(search_job).body
    until job_finished?(status['state'])
      sleep(2)
      status = sumo.search_job_status(search_job).body
    end

    limit = 200
    if status['state'] == 'DONE GATHERING RESULTS'
      if status['recordCount'].to_i > 0
        SumoAggregateResult.new(
          status,
          sumo.search_job_messages(search_job, limit).body,
          sumo.search_job_records(search_job, limit).body
        )
      else
        SumoResult.new(
          status,
          sumo.search_job_messages(search_job, limit).body
        )
      end
    else
      raise "Job status #{status['state']}"
    end
  end

  def job_finished?(state)
    ['DONE GATHERING RESULTS', 'CANCELLED'].include?(state)
  end

end