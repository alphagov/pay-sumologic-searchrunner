require 'sumo_result'

class SumoAggregateResult < SumoResult
  attr_reader :aggregate_results
  def initialize(status, messages, aggregate_results)
    super(status, messages)
    @aggregate_results = aggregate_results
  end


  def print
    puts "aggregate_results"
    pp aggregate_results

    fields = aggregate_results['fields']
    table = Terminal::Table.new do |t|
      field_names = fields.map {|f| f['name'] }
      # Table headers
      t << field_names
      t << :separator

      # Table body
      aggregate_results['records'].each do |record|
        t << field_names.map { |field_name| record['map'][field_name] }
      end
    end

    puts table
  end
end