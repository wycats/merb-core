require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require File.join(File.dirname(__FILE__), "shared_example_groups")


Merb::Router.prepare do |r|
  r.resources :users
end

class Users < Merb::Controller
  def new
    body = "<div><form action='/users' method='POST'></form></div>"
    body
  end

  def index
    body = "<div>This is my index action</div>"
    body
  end

  def edit
    body = "<div><form action='/users' method='POST'></form><form action='/sessions' method='POST'></form></div>"
  end

  def create

  end
end


describe Merb::Rack::Csrf do
  before(:each) do
    @app = Merb::Rack::Application.new
    @middleware = Merb::Rack::Csrf.new(@app)
    @env = Rack::MockRequest.env_for('/users/new')
    
    Merb::Config[:session_secret_key] = "ABC"
  end

  it "should be successful" do
    env = Rack::MockRequest.env_for('/users', :method => 'POST', 'csrf_authentication_token' => "b072aa15485e028dc8973d48089efe0e")
    status, header, body = @middleware.call(env)
    status.should == 200
  end

  it "should return a Merb::ExceptionsController::Forbidden (403)" do
    env = Rack::MockRequest.env_for('/users', :method => 'POST', 'csrf_authentication_token' => "INCORRECT_AUTH_TOKEN")
    status, header, body = @middleware.call(env)
    status.should == 403
  end

  it "should insert a hidden field in to any form with a POST method" do
    env = Rack::MockRequest.env_for('/users/new')
    status, header, body = @middleware.call(env)
    body.should have_tag(:form, :action => '/users')
      body.should have_tag(:input, :type => 'hidden', :id => 'csrf_authentication_token')
  end

  it "should not do anything if there is no form found in the response" do
    env = Rack::MockRequest.env_for('/users')
    status, header, body = @middleware.call(env)
    body.should not_match_tag('form')
  end

  it "should insert hidden fields in to both forms" do
    env = Rack::MockRequest.env_for('/users/1/edit')
    status, header, body = @middleware.call(env)
    body.should have_tag(:form, :action => '/users')
    body.should have_tag(:form, :action => '/sessions')
  end
end