#!/usr/bin/env ruby
require 'bunny'
require 'securerandom'
require 'faker'
require 'json'

STDOUT.sync = true

class QueryServer
  def initialize
    conn_string = ENV.fetch 'AMQP_URL', 'amqp://guest:guest@localhost:5672'
    @connection = Bunny.new conn_string
    @connection.start
    @channel = @connection.create_channel
  end

  def start
    @exchange = channel.topic('rpc.calls')

    queue_name = "procedures.query.server-#{SecureRandom.uuid}"
    @queue = channel
      .queue(queue_name, exclusive: true, auto_delete: true)
      .bind(exchange, routing_key: 'procedures.query')

    subscribe_to_queue
  end

  def stop
    channel.close
    connection.close
  end

  private

  attr_reader :channel, :exchange, :queue, :connection

  def subscribe_to_queue
    queue.subscribe(block: true) do |_delivery_info, properties, payload|
      puts "  -> Received payload '#{payload}'"

      result = query(payload.to_i)
      puts "  <- Publishing result '#{result}' to #{properties.reply_to}" \
           " (Correlation ID: #{properties.correlation_id})"

      exchange.publish(
        result.to_s,
        routing_key: properties.reply_to,
        correlation_id: properties.correlation_id
      )
    end
  end

  def query(parameter)
    return JSON.generate([{ name: Faker::FunnyName.two_word_name }])
  end
end

begin
  server = QueryServer.new

  puts ' [x] Awaiting RPC requests'
  server.start
rescue Interrupt => _
  server.stop
end
