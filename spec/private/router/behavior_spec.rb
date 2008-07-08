require File.dirname(__FILE__) + '/../../spec_helper'
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

def match_for(path, args = {}, protocol = "http://")
  Merb::Router.match(SimpleRequest.new({:protocol => protocol, :path => path}.merge(args)))
end

def matched_route_for(*args)
  # get route index
  idx = match_for(*args)[0]

  Merb::Router.routes[idx]
end

describe Merb::Router::Behavior, "#redirect" do
  predicate_matchers[:redirect] = :redirects?

  before :each do
    Merb::Router.prepare do |r|
      r.match('/old/location').redirect("/new/location", true)
    end
  end

  it "makes route redirecting" do
    @behavior = matched_route_for("/old/location").behavior
    @behavior.should redirect
  end
end



describe Merb::Router::Behavior, "#defer_to" do
  before :each do
    Merb::Router.prepare do |r|      
      r.match("/deferred/:zoo").defer_to do |request, params|
        params.merge(:controller => "w00t") if params[:zoo]
      end
      r.default_routes
    end    
  end

  it "registers route properly so it has index" do
    matched_route_for("/deferred/abc").index.should_not be(nil)
  end
end
