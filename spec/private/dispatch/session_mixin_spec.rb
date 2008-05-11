require File.join(File.dirname(__FILE__), "spec_helper")
Merb.start :environment => "test"

describe Merb::SessionMixin do

  before :each do
    @first_session_finalizer_executed  = false
    @second_session_finalizer_executed = false

    @first_session_persisting_callback_executed  = false
    @second_session_persisting_callback_executed = false
  end

  it "stores session finalizing callbacks in a collection" do
    Merb::SessionMixin.finalize_session_exception_callbacks do
      @first_session_finalizer_executed = true
    end

    Merb::SessionMixin.finalize_session_exception_callbacks do
      @second_session_finalizer_executed = true
    end

    Merb::SessionMixin.finalize_session_exception_callbacks.each { |callback| callback.call }

    @first_session_finalizer_executed.should  == true
    @second_session_finalizer_executed.should == true
  end

  it "stores session persist callbacks in a collection" do
    Merb::SessionMixin.persist_exception_callbacks do
      @first_session_finalizer_executed = true
    end

    Merb::SessionMixin.persist_exception_callbacks do
      @second_session_finalizer_executed = true
    end

    Merb::SessionMixin.persist_exception_callbacks.each { |callback| callback.call }

    @first_session_finalizer_executed.should  == true
    @second_session_finalizer_executed.should == true
  end

  it "generates random 32 character uuid string" do
    Merb::SessionMixin.rand_uuid.size.should == 32
  end
end
