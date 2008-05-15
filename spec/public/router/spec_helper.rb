require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require 'ostruct'

require 'rack/mock'
require 'stringio'
Merb.start :environment => 'test',
           :merb_root => File.dirname(__FILE__) / 'fixture'


class SimpleRequest < OpenStruct

  def method
    @table[:method]
  end

  def params
    @table
  end
end

def prepare_route(from, to)
  Merb::Router.prepare {|r| r.match(from).to(to)}
end

def route_to(path, args = {}, protocol = "http://")
  Merb::Router.match(SimpleRequest.new({:protocol => protocol, :path => path}.merge(args)))[1]
end

def match_for(path, args = {}, protocol = "http://")
  Merb::Router.match(SimpleRequest.new({:protocol => protocol, :path => path}.merge(args)))
end

def matched_route_for(*args)
  # get route index
  idx = match_for(*args)[0]

  Merb::Router.routes[idx]
end

def generate(*args)
  Merb::Router.generate *args
end

module Merb

  module Test

    module RspecMatchers

      class HaveRoute

        def self.build(expected)
          this = new
          this.instance_variable_set("@expected", expected)
          this
        end

        def matches?(target)
          @target = target
          @errors = []
          @expected.all? { |param, value| @target[param] == value }
        end

        def failure_message
          @target.each do |param, value|
            @errors << "Expected :#{param} to be #{@expected[param].inspect}, but was #{value.inspect}" unless
              @expected[param] == value
          end
          @errors << "Got #{@target.inspect}"
          @errors.join("\n")
        end

        def negative_failure_message
          "Expected #{@expected.inspect} not to be #{@target.inspect}, but it was."
        end

        def description() "have_route #{@target.inspect}" end
      end

      def have_route(expected)
        HaveRoute.build(expected)
      end

      def have_nil_route
        have_route({})
      end

    end
  end
end
