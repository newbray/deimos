# frozen_string_literal: true

# This file is autogenerated by Deimos, Do NOT modify
module Schemas; module MyNamespace
  ### Primary Schema Class ###
  # Autogenerated Schema for Record at com.my-namespace.MySchemaCompound_key
  class MySchemaCompoundKey < Deimos::SchemaClass::Record

    ### Attribute Accessors ###
    # @return [String]
    attr_accessor :part_one
    # @return [String]
    attr_accessor :part_two

    # @override
    def initialize(part_one: nil,
                   part_two: nil)
      super
      self.part_one = part_one
      self.part_two = part_two
    end

    # @override
    def schema
      'MySchemaCompound_key'
    end

    # @override
    def namespace
      'com.my-namespace'
    end

    # @override
    def as_json(_opts={})
      {
        'part_one' => @part_one,
        'part_two' => @part_two
      }
    end
  end
end; end