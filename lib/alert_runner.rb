class AlertRunner
  attr_reader :search_runner, :search_definition_file, :from_time, :to_time, :time_zone

  def initialize(search_definition_file, search_runner:)
    @search_runner = search_runner
    @search_definition_file = search_definition_file
    @from_time = '2018-05-04T12:00:00Z'
    @to_time = Time.now.iso8601
    @time_zone = 'UTC'
  end

  def searches
    @searches ||= JSON.parse(File.read(search_definition_file))['children']
  end

  def run!
    searches.each do |search|
      puts "Re-running '#{search['name']}' between #{from_time} and #{to_time}"
      query = search['searchQuery']
      matcher = ThresholdMatcher.for(search.fetch('schedules', {})['thresholdOption'])
      if matcher
        result = search_runner.run_query(query, from_time, to_time, time_zone)
        matcher.describe_alert(result)
      else
        puts "OK    Skipping (no threshold configured)"
      end

      puts ""
    end
  end


  class ThresholdMatcher
    attr_reader :type, :operator, :count

    def initialize(options)
      @type = options['type']
      @operator = options['operator']
      @count = options['count']
    end

    def self.for(threshold_option)
      return nil unless threshold_option
      if threshold_option['type'] == 'GroupThreshold'
        return GroupThreshold.new(threshold_option)
      elsif threshold_option['type'] == 'MessageThreshold'
        if threshold_option['operator'] == 'eq'
          return MessageThresholdEq.new(threshold_option)
        else
          return MessageThresholdGt.new(threshold_option)
        end
      end
    end

  end

  class GroupThreshold < ThresholdMatcher
    def initialize(options)
      super(options)
      raise "Illegal type #{type}" unless type == 'GroupThreshold'
      raise "Illegal operator #{operator}" unless operator == 'gt'
      raise "Illegal count #{count}" unless count == 0
    end

    def describe_alert(sumo_result)
      if sumo_result.is_a?(SumoAggregateResult) && sumo_result.record_count > 0
        puts "ALERT aggregate matched!"
        sumo_result.print
      elsif sumo_result.is_a?(SumoResult) && sumo_result.message_count > 0
        puts "ALERT messages matched!"
        sumo_result.print
      else
        puts "OK    exepected no results, got #{sumo_result.record_count} aggregates, #{sumo_result.message_count} messages"
      end
    end
  end

  class MessageThresholdEq < ThresholdMatcher
    def initialize(options)
      super(options)
      raise "Illegal type #{type}" unless type == 'MessageThreshold'
      raise "Illegal operator #{operator}" unless %w{eq}.include?(operator)
      raise "Illegal count #{count}" unless count == 0
    end

    def describe_alert(sumo_result)  
      if sumo_result.message_count == 0
        puts "ALERT expected some messages but #{sumo_result.message_count} found"
        sumo_result.print
      else
        puts "OK    expected some messages, #{sumo_result.message_count} found"
      end
    end
  end

  class MessageThresholdGt < ThresholdMatcher
    def initialize(options)
      super(options)
      raise "Illegal type #{type}" unless type == 'MessageThreshold'
      raise "Illegal operator #{operator}" unless %w{gt}.include?(operator)
      raise "Illegal count #{count}" unless count == 0
    end

    def describe_alert(sumo_result)  
      if sumo_result.message_count > 0
        puts "ALERT expected no messages, but #{sumo_result.message_count} found"
        sumo_result.print
      else
        puts "OK    expected no messages, #{sumo_result.message_count} found"
      end
    end
  end

end