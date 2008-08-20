module Merb::Test::Rspec::ViewMatchers
  class HaveXpath
    def initialize(expected)
      @expected = expected
    end
    
    def matches?(stringlike)
      @document = case stringlike
      when LibXML::XML::Document, LibXML::XML::Node
        stringlike
      when StringIO
        LibXML::XML::HTMLParser.string(stringlike.string).parse
      else
        LibXML::XML::HTMLParser.string(stringlike).parse
      end
      !@document.find(@expected).empty?
    end
    
    # ==== Returns
    # String:: The failure message.
    def failure_message
      "expected following text to match xpath #{@expected}:\n#{@document}"
    end

    # ==== Returns
    # String:: The failure message to be displayed in negative matches.
    def negative_failure_message
      "expected following text to not match xpath #{@expected}:\n#{@document}"
    end    
  end
  
  class HaveSelector

    # ==== Parameters
    # expected<String>:: The string to look for.
    def initialize(expected)
      @expected = expected
    end

    # ==== Parameters
    # stringlike<Hpricot::Elem, StringIO, String>:: The thing to search in.
    #
    # ==== Returns
    # Boolean:: True if there was at least one match.
    def matches?(stringlike)
      @document = case stringlike
      when Hpricot::Elem
        stringlike
      when StringIO
        Hpricot.parse(stringlike.string)
      else
        Hpricot.parse(stringlike)
      end
      !@document.search(@expected).empty?
    end

    # ==== Returns
    # String:: The failure message.
    def failure_message
      "expected following text to match selector #{@expected}:\n#{@document}"
    end

    # ==== Returns
    # String:: The failure message to be displayed in negative matches.
    def negative_failure_message
      "expected following text to not match selector #{@expected}:\n#{@document}"
    end
  end

  class MatchTag

    # ==== Parameters
    # name<~to_s>:: The name of the tag to look for.
    # attrs<Hash>:: Attributes to look for in the tag (see below).
    #
    # ==== Options (attrs)
    # :content<String>:: Optional content to match.
    def initialize(name, attrs)
      @name, @attrs = name, attrs
      @content = @attrs.delete(:content)
    end

    # ==== Parameters
    # target<String>:: The string to look for the tag in.
    #
    # ==== Returns
    # Boolean:: True if the tag matched.
    def matches?(target)
      @errors = []
      unless target.include?("<#{@name}")
        @errors << "Expected a <#{@name}>, but was #{target}"
      end
      @attrs.each do |attr, val|
        unless target.include?("#{attr}=\"#{val}\"")
          @errors << "Expected #{attr}=\"#{val}\", but was #{target}"
        end
      end
      if @content
        unless target.include?(">#{@content}<")
          @errors << "Expected #{target} to include #{@content}"
        end
      end
      @errors.size == 0
    end

    # ==== Returns
    # String:: The failure message.
    def failure_message
      @errors[0]
    end

    # ==== Returns
    # String:: The failure message to be displayed in negative matches.
    def negative_failure_message
      "Expected not to match against <#{@name} #{@attrs.map{ |a,v| "#{a}=\"#{v}\"" }.join(" ")}> tag, but it matched"
    end
  end

  class NotMatchTag

    # === Parameters
    # attrs<Hash>:: A set of attributes that must not be matched.
    def initialize(attrs)
      @attrs = attrs
    end

    # ==== Parameters
    # target<String>:: The target to look for the match in.
    #
    # ==== Returns
    # Boolean:: True if none of the attributes were matched.
    def matches?(target)
      @errors = []
      @attrs.each do |attr, val|
        if target.include?("#{attr}=\"#{val}\"")
          @errors << "Should not include #{attr}=\"#{val}\", but was #{target}"
        end
      end
      @errors.size == 0
    end

    # ==== Returns
    # String:: The failure message.
    def failure_message
      @errors[0]
    end
  end
  
  class HasTag
    
    # ==== Parameters
    # tag<~to_s>:: The tag to look for.
    # attributes<Hash>:: Attributes for the tag (see below).
    def initialize(tag, attributes = {}, &blk)
      @tag, @attributes = tag, attributes
      @id, @class = @attributes.delete(:id), @attributes.delete(:class)
      @blk = blk
    end

    # ==== Parameters
    # stringlike<Hpricot::Elem, StringIO, String>:: The thing to search in.
    # &blk:: An optional block for searching in child elements using with_tag.
    #
    # ==== Returns
    # Boolean:: True if there was at least one match.
    def matches?(stringlike, &blk)
      @document = case stringlike
      when Hpricot::Elem
        stringlike
      when StringIO
        Hpricot.parse(stringlike.string)
      else
        Hpricot.parse(stringlike)
      end
      
      @blk = blk unless blk.nil?

      unless @blk.nil?
        !@document.search(selector).select do |ele|
          @blk.call ele
          true
        end.empty?
      else
        !@document.search(selector).empty?
      end
    end

    # ==== Returns
    # String:: The complete selector for element queries.
    def selector
      @selector = "//#{@tag}#{id_selector}#{class_selector}"
      @selector << @attributes.map{|a, v| "[@#{a}=\"#{v}\"]"}.join

      @selector << @inner_has_tag.selector unless @inner_has_tag.nil?

      @selector
    end

    # ==== Returns
    # String:: ID selector for use in element queries.
    def id_selector
      "##{@id}" if @id
    end

    # ==== Returns
    # String:: Class selector for use in element queries.
    def class_selector
      ".#{@class}" if @class
    end

    # ==== Returns
    # String:: The failure message.
    def failure_message
      "expected following output to contain a #{tag_for_error} tag:\n#{@document}"
    end

    # ==== Returns
    # String:: The failure message to be displayed in negative matches.
    def negative_failure_message
      "expected following output to omit a #{tag_for_error} tag:\n#{@document}"
    end
    
    # ==== Returns
    # String:: The tag used in failure messages.
    def tag_for_error
      "#{inner_failure_message}<#{@tag}#{id_for_error}#{class_for_error}#{attributes_for_error}>"
    end

    # ==== Returns
    # String::
    #   The failure message to be displayed in negative matches within the
    #   have_tag block.
    def inner_failure_message
      "#{@inner_has_tag.tag_for_error} tag within a " unless @inner_has_tag.nil?
    end

    # ==== Returns
    # String:: ID for the error tag.
    def id_for_error
      " id=\"#{@id}\"" unless @id.nil?
    end

    # ==== Returns
    # String:: Class for the error tag.
    def class_for_error
      " class=\"#{@class}\"" unless @class.nil?
    end

    # ==== Returns
    # String:: Class for the error tag.
    def attributes_for_error
      @attributes.map{|a,v| " #{a}=\"#{v}\""}.join
    end

    # Search for a child tag within a have_tag block.
    #
    # ==== Parameters
    # tag<~to_s>:: The tag to look for.
    # attributes<Hash>:: Attributes for the tag (see below).
    def with_tag(name, attrs={})
      @inner_has_tag = HasTag.new(name, attrs)
    end
  end

  class HasContent
    def initialize(content)
      @content = content
    end

    def matches?(element)
      @element = element
      
      case @content
      when String
        @element.contains?(@content)
      when Regexp
        @element.matches?(@content)
      end
    end
    
    # ==== Returns
    # String:: The failure message.
    def failure_message
      "expected the following element's content to #{content_message}:\n#{@element.inner_text}"
    end

    # ==== Returns
    # String:: The failure message to be displayed in negative matches.
    def negative_failure_message
      "expected the following element's content to not #{content_message}:\n#{@element.inner_text}"
    end
    
    def content_message
      case @content
      when String
        "include \"#{@content}\""
      when Regexp
        "match #{@content.inspect}"
      end
    end
  end
  
  # ==== Parameters
  # name<~to_s>:: The name of the tag to look for.
  # attrs<Hash>:: Attributes to look for in the tag (see below).
  #
  # ==== Options (attrs)
  # :content<String>:: Optional content to match.
  #
  # ==== Returns
  # MatchTag:: A new match tag matcher.
  def match_tag(name, attrs={})
    MatchTag.new(name, attrs)
  end

  # ==== Parameters
  # attrs<Hash>:: A set of attributes that must not be matched.
  #
  # ==== Returns
  # NotMatchTag:: A new not match tag matcher.
  def not_match_tag(attrs)
    NotMatchTag.new(attrs)
  end

  # ==== Parameters
  # expected<String>:: The string to look for.
  #
  # ==== Returns
  # HaveSelector:: A new have selector matcher.
  def have_selector(expected)
    HaveSelector.new(expected)
  end
  alias_method :match_selector, :have_selector

  def have_xpath(expected)
    require "libxml"
    HaveXpath.new(expected)
  end
  alias_method :match_xpath, :have_xpath

  # RSpec matcher to test for the presence of tags.
  #
  # ==== Parameters
  # tag<~to_s>:: The name of the tag.
  # attributes<Hash>:: Tag attributes.
  #
  # ==== Returns
  # HasTag:: A new has tag matcher.
  #
  # ==== Examples
  #   # Check for <div>
  #   body.should have_tag("div")
  #
  #   # Check for <span id="notice">
  #   body.should have_tag("span", :id => :notice)
  #
  #   # Check for <h1 id="foo" class="bar">
  #   body.should have_tag(:h2, :class => "bar", :id => "foo")
  #
  #   # Check for <div attr="val">
  #   body.should have_tag(:div, :attr => :val)
  def have_tag(tag, attributes = {}, &blk)
    HasTag.new(tag, attributes, &blk)
  end

  alias_method :with_tag, :have_tag
  
  def contain(content)
    HasContent.new(content)
  end
end
