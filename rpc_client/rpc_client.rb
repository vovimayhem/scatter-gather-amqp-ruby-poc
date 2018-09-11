#!/usr/bin/env ruby
require 'bunny'
require 'thread'
require 'securerandom'
require 'json'

class QueryService
  QUERY_WAIT_IN_SECONDS = 2

  attr_accessor :call_id, :responses, :lock, :condition, :connection,
                :channel, :reply_queue, :exchange

  def initialize()
    conn_string = ENV.fetch 'AMQP_URL', 'amqp://guest:guest@localhost:5672'
    @connection = Bunny.new(conn_string, automatically_recover: false)
    @connection.start

    @channel = connection.create_channel
    @exchange = channel.topic('rpc.calls')

    setup_reply_queue
  end

  def call(n)
    @call_id = SecureRandom.uuid
    @responses = []

    exchange.publish(n.to_s,
                     routing_key: 'procedures.query',
                     correlation_id: call_id,
                     reply_to: reply_queue.name)

    # wait for the signal to continue the execution
    lock.synchronize { condition.wait(lock, QUERY_WAIT_IN_SECONDS) }

    responses
  end

  def stop
    channel.close
    connection.close
  end

  private

  def setup_reply_queue
    @lock = Mutex.new
    @condition = ConditionVariable.new
    that = self

    # We'll create a reply queue. This will be binded to the exchange using a
    # routing key with the same name as the queue:
    queue_name = "reply-to-#{SecureRandom.uuid}"
    @reply_queue = channel
      .queue(queue_name, exclusive: true)
      .bind(exchange, routing_key: queue_name)

    # We'll subscribe a callback to the reply queue:
    reply_queue.subscribe do |_delivery_info, properties, payload|
      if properties[:correlation_id] == that.call_id
        that.responses << JSON.parse(payload)
      end
    end
  end
end

client = QueryService.new

num = 23
puts " [x] Requesting query(#{num})"
response = client.call(num)

puts " [.] Got #{response.inspect}"

client.stop
