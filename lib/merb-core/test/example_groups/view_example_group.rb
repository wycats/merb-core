# Based on Spec::Rails::Example::ViewExampleGroup from RSpec

module Merb::Test::Rspec::Example
  # View Specs live in spec/views/.
  #
  # View Specs use Merb::Test::Rspec::Example::ViewExampleGroup, which provides
  # access to views without invoking any of your controllers.
  #
  # ==== Example
  #
  #   describe "articles/show.html" do
  #     before do
  #       article = mock('article')
  #       article.stub!(:title) = "FooBar"
  #       article.stub!(:body) = "Lorem Ipsum..."
  #       assign[:article] = article
  #       render 'articles/index.html', :helper => Merb::ArticlesHelper
  #     end
  #
  #     it "should display the title" do
  #       body.should include('<h1>FooBar</h1>')
  #     end
  #
  #     ...
  #   end
  #
  class ViewExampleGroup < MerbExampleGroup
    include Merb::Test::Rspec::ViewMatchers

    Spec::Example::ExampleGroupFactory.register(:view, self)
  end
end