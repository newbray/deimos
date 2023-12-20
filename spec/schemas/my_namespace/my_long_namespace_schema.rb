# frozen_string_literal: true

# This file is autogenerated by Deimos, Do NOT modify
module Schemas; module MyNamespace
  ### Primary Schema Class ###
  # Autogenerated Schema for Record at com.my-namespace.my-suborg.MyLongNamespaceSchema
  class MyLongNamespaceSchema < Deimos::SchemaClass::Record

    ### Attribute Accessors ###
    # @return [String]
    attr_accessor :test_id
    # @return [Integer]
    attr_accessor :some_int

    # @override
    def initialize(test_id: nil,
                   some_int: nil)
      super
      self.test_id = test_id
      self.some_int = some_int
    end

    # @override
    def schema
      'MyLongNamespaceSchema'
    end

    # @override
    def namespace
      'com.my-namespace.my-suborg'
    end

    def self.tombstone(key)
      record = self.allocate
      record.tombstone_key = key
      record.test_id = key
      record
    end

    # @override
    def as_json(_opts={})
      {
        'test_id' => @test_id,
        'some_int' => @some_int
      }
    end
  end
end; end