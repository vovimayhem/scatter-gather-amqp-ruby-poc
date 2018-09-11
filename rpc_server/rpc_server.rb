#!/usr/bin/env ruby
require 'bunny'
require 'securerandom'

STDOUT.sync = true

class FibonacciServer
  def initialize
    conn_string = ENV.fetch 'AMQP_URL', 'amqp://guest:guest@localhost:5672'
    @connection = Bunny.new conn_string
    @connection.start
    @channel = @connection.create_channel
  end

  def start
    @exchange = channel.topic('rpc.calls')

    queue_name = "procedures.fibonacci.server-#{SecureRandom.uuid}"
    @queue = channel
      .queue(queue_name, exclusive: true, auto_delete: true)
      .bind(exchange, routing_key: 'procedures.fibonacci')

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

      result = fibonacci(payload.to_i)
      puts "  -> Publishing result '#{result}' to #{properties.reply_to}" \
           " (Correlation ID: #{properties.correlation_id})"

      exchange.publish(
        result.to_s,
        routing_key: properties.reply_to,
        correlation_id: properties.correlation_id
      )
    end
  end

  def fibonacci(value)
    return value if value.zero? || value == 1

    fibonacci(value - 1) + fibonacci(value - 2)
  end
end

begin
  server = FibonacciServer.new

  puts ' [x] Awaiting RPC requests'
  server.start
rescue Interrupt => _
  server.stop
end
