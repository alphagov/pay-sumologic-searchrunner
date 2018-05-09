require 'sumologic'
require 'pp'
require 'terminal-table'

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
        puts "Aggregate results (over #{status['messageCount']} message(s))"
        output_aggregate_results(sumo.search_job_records(search_job, limit).body)

        puts "Messages:"
        output_search_results(sumo.search_job_messages(search_job, limit).body)
      else
        puts "Found #{status['messageCount']} result(s)"
        output_search_results(sumo.search_job_messages(search_job, limit).body)
      end
    end
  end

  def output_aggregate_results(results)
    pp results

    fields = results['fields']
    table = Terminal::Table.new do |t|
      field_names = fields.map {|f| f['name'] }
      # Table headers
      t << field_names
      t << :separator

      # Table body
      results['records'].each do |record|
        t << field_names.map { |field_name| record['map'][field_name] }
      end
    end

    puts table
  end

  def output_search_results(results)
    results['messages'].each do |message|
      raw = JSON.parse(message['map']['_raw'])
      puts raw['message']
    end
  end

  def job_finished?(state)
    ['DONE GATHERING RESULTS', 'CANCELLED'].include?(state)
  end

end