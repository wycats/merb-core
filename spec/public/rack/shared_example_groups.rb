describe "rack application", :shared => true do
  it 'is callable' do
    @app.should respond_to(:call)
  end

  it 'returns a 3-tuple' do
    @result.size.should == 3
  end

  it 'returns status as first tuple element' do
    @result.first.should == 200
  end

  it 'returns hash of headers as the second tuple element' do
    @result[1].should be_an_instance_of(Hash)
  end

  it 'returns response body as third tuple element' do
    @result.last.should == @body
  end
end

describe "transparent middleware", :shared => true do
  it "delegates request handling to wrapped Rack application" do
    @result.last.should == @body
  end

  describe "#deferred?" do
    it "is delegated to wrapped Rack application" do
      @middleware.deferred?(@env).should be(true)
      @middleware.deferred?(Rack::MockRequest.env_for('/not-deferred/')).should be(false)
    end
  end
end

