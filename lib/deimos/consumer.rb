# frozen_string_literal: true

require 'deimos/avro_data_decoder'
require 'deimos/base_consumer'
require 'deimos/shared_config'
require 'phobos/handler'
require 'active_support/all'
require 'ddtrace'

# Class to consume messages coming from the pipeline topic
# Note: According to the docs, instances of your handler will be created
# for every incoming message. This class should be lightweight.
module Deimos
  # Parent consumer class.
  class Consumer < BaseConsumer
    include Phobos::Handler

    # :nodoc:
    def around_consume(payload, metadata)
      _received_message(payload, metadata)
      benchmark = Benchmark.measure do
        _with_error_span(payload, metadata) { yield }
      end
      _handle_success(benchmark.real, payload, metadata)
    end

    # :nodoc:
    def before_consume(payload, metadata)
      _with_error_span(payload, metadata) do
        if self.class.config[:key_schema] || self.class.config[:key_field]
          metadata[:key] = decode_key(metadata[:key])
        end
        self.class.decoder.decode(payload) if payload.present?
      end
    end

    # Consume incoming messages.
    # @param _payload [String]
    # @param _metadata [Hash]
    def consume(_payload, _metadata)
      raise NotImplementedError
    end

  private

    def _received_message(payload, metadata)
      Deimos.config.logger.info(
        message: 'Got Kafka event',
        payload: payload,
        metadata: metadata
      )
      Deimos.config.metrics&.increment('handler', tags: %W(
                                         status:received
                                         topic:#{metadata[:topic]}
                                       ))
      _report_time_delayed(payload, metadata)
    end

    # @param exception [Throwable]
    # @param payload [Hash]
    # @param metadata [Hash]
    def _handle_error(exception, payload, metadata)
      Deimos.config.metrics&.increment(
        'handler',
        tags: %W(
          status:error
          topic:#{metadata[:topic]}
        )
      )
      Deimos.config.logger.warn(
        message: 'Error consuming message',
        handler: self.class.name,
        metadata: metadata,
        data: payload,
        error_message: exception.message,
        error: exception.backtrace
      )
      super
    end

    # @param time_taken [Float]
    # @param payload [Hash]
    # @param metadata [Hash]
    def _handle_success(time_taken, payload, metadata)
      Deimos.config.metrics&.histogram('handler', time_taken, tags: %W(
                                         time:consume
                                         topic:#{metadata[:topic]}
                                       ))
      Deimos.config.metrics&.increment('handler', tags: %W(
                                         status:success
                                         topic:#{metadata[:topic]}
                                       ))
      Deimos.config.logger.info(
        message: 'Finished processing Kafka event',
        payload: payload,
        time_elapsed: time_taken,
        metadata: metadata
      )
      return if payload.nil? || payload['timestamp'].blank?

      begin
        time_delayed = Time.now.in_time_zone - payload['timestamp'].to_datetime
      rescue ArgumentError
        Deimos.config.logger.info(
          message: "Error parsing timestamp! #{payload['timestamp']}"
        )
        return
      end
      Deimos.config.metrics&.histogram('handler', time_delayed, tags: %W(
                                         time:time_delayed
                                         topic:#{metadata[:topic]}
                                       ))
    end
  end
end
