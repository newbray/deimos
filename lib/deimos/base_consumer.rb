# frozen_string_literal: true

module Deimos
  class BaseConsumer
    include SharedConfig

    class << self
      # @return [AvroDataEncoder]
      def decoder
        @decoder ||= AvroDataDecoder.new(schema: config[:schema],
                                         namespace: config[:namespace])
      end

      # @return [AvroDataEncoder]
      def key_decoder
        @key_decoder ||= AvroDataDecoder.new(schema: config[:key_schema],
                                             namespace: config[:namespace])
      end
    end

    # Helper method to decode an Avro-encoded key.
    # @param key [String]
    # @return [Object] the decoded key.
    def decode_key(key)
      return nil if key.nil?

      config = self.class.config
      if config[:encode_key] && config[:key_field].nil? &&
         config[:key_schema].nil?
        raise 'No key config given - if you are not decoding keys, please use '\
          '`key_config plain: true`'
      end

      if config[:key_field]
        self.class.decoder.decode_key(key, config[:key_field])
      elsif config[:key_schema]
        self.class.key_decoder.decode(key, schema: config[:key_schema])
      else # no encoding
        key
      end
    end

  protected

    # @param payload [Hash|String]
    # @param metadata [Hash]
    def _with_error_span(payload, metadata)
      @span = Deimos.config.tracer&.start(
        'deimos-consumer',
        resource: self.class.name.gsub('::', '-')
      )
      yield
    rescue StandardError => e
      _handle_error(e, payload, metadata)
    ensure
      Deimos.config.tracer&.finish(@span)
    end

    def _report_time_delayed(payload, metadata)
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

    # @param exception [Throwable]
    # @param payload [Hash]
    # @param metadata [Hash]
    def _handle_error(exception, payload, metadata)
      Deimos.config.tracer&.set_error(@span, exception)

      raise if Deimos.config.reraise_consumer_errors
    end

    # @param time_taken [Float]
    # @param payload [Hash]
    # @param metadata [Hash]
    def _handle_success(time_taken, payload, metadata)
      raise NotImplementedError
    end
  end
end
