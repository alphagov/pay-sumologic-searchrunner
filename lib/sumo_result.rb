class SumoResult
  attr_reader :status, :messages

  def initialize(status, messages)
    @status = status
    @messages = messages
  end

  def print(limit = 10)
    puts "#{messages['messages'].size} of #{message_count} message(s)"
    messages['messages'].take(limit).each.with_index do |message, i|
      raw = JSON.parse(message['map']['_raw'])
      printf "%3d: %s\n", i, raw['message']
    end
  end

  def message_count
    status['messageCount'].to_i
  end

  def record_count
    status['recordCount'].to_i
  end
end