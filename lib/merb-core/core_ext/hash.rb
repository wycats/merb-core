class Hash
  class << self
    # Converts valid XML into a Ruby Hash structure.
    #
    # ==== Paramters
    # xml<String>:: A string representation of valid XML.
    #
    # ==== Notes
    # * Mixed content is treated as text and any tags in it are left unparsed
    # * Any attributes other than type on a node containing a text node will be
    #   discarded
    #
    # ===== Typecasting
    # Typecasting is performed on elements that have a +type+ attribute:
    # integer:: 
    # boolean:: Anything other than "true" evaluates to false.
    # datetime::
    #   Returns a Time object. See Time documentation for valid Time strings.
    # date::
    #   Returns a Date object. See Date documentation for valid Date strings.
    # 
    # Keys are automatically converted to +snake_case+
    #
    # ==== Examples
    #
    # ===== Standard
    #   <user gender='m'>
    #     <age type='integer'>35</age>
    #     <name>Home Simpson</name>
    #     <dob type='date'>1988-01-01</dob>
    #     <joined-at type='datetime'>2000-04-28 23:01</joined-at>
    #     <is-cool type='boolean'>true</is-cool>
    #   </user>
    #
    # evaluates to 
    # 
    #   { "user" => { 
    #       "gender"    => "m",
    #       "age"       => 35,
    #       "name"      => "Home Simpson",
    #       "dob"       => DateObject( 1998-01-01 ),
    #       "joined_at" => TimeObject( 2000-04-28 23:01),
    #       "is_cool"   => true 
    #     }
    #   }
    #
    # ===== Mixed Content
    #   <story>
    #     A Quick <em>brown</em> Fox
    #   </story>
    #
    # evaluates to
    #
    #   { "story" => "A Quick <em>brown</em> Fox" }
    # 
    # ====== Attributes other than type on a node containing text
    #   <story is-good='false'>
    #     A Quick <em>brown</em> Fox
    #   </story>
    #
    # evaluates to
    #
    #   { "story" => "A Quick <em>brown</em> Fox" }
    #
    #   <bicep unit='inches' type='integer'>60</bicep>
    #
    # evaluates with a typecast to an integer. But unit attribute is ignored.
    #
    #    { "bicep" => 60 }
    def from_xml( xml )
      ToHashParser.from_xml(xml)
    end
  end
  
  # ==== Returns
  # Mash:: This hash as a Mash for string or symbol key access.
  def to_mash
    hash = Mash.new(self)
    hash.default = default
    hash
  end
  
  # ==== Returns
  # String:: This hash as a query string
  #
  # ==== Examples
  #   { :name => "Bob",
  #     :address => {
  #       :street => '111 Ruby Ave.',
  #       :city => 'Ruby Central',
  #       :phones => ['111-111-1111', '222-222-2222']
  #     }
  #   }.to_params
  #     #=> "name=Bob&address[city]=Ruby Central&address[phones]=111-111-1111222-222-2222&address[street]=111 Ruby Ave."
  def to_params
    params = ''
    stack = []
    
    each do |k, v|
      if v.is_a?(Hash)
        stack << [k,v]
      else
        params << "#{k}=#{v}&"
      end
    end
    
    stack.each do |parent, hash|
      hash.each do |k, v|
        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          params << "#{parent}[#{k}]=#{v}&"
        end
      end
    end
    
    params.chop! # trailing &
    params
  end
  
  # ==== Parameters
  # allowed<Array>:: The hash keys to include.
  #
  # ==== Returns
  # Hash:: A new hash with only the selected keys.
  #
  # ==== Examples
  #   { :one => 1, :two => 2, :three => 3 }.only(:one)
  #     #=> { :one => 1 }
  def only(*allowed) 
    reject { |k,v| !allowed.include?(k) }
  end
  
  # ==== Parameters
  # rejected<Array>:: The hash keys to exclude.
  #
  # ==== Returns
  # Hash:: A new hash without the selected keys.
  #
  # ==== Examples
  #   { :one => 1, :two => 2, :three => 3 }.except(:one)
  #     #=> { :two => 2, :three => 3 }
  def except(*rejected) 
    reject { |k,v| rejected.include?(k) }
  end
  
  # ==== Returns
  # String:: The hash as attributes for an XML tag.
  #
  # ==== Examples
  #   { :one => 1, "two"=>"TWO" }.to_xml_attributes
  #     #=> 'one="1" two="TWO"'
  def to_xml_attributes
    map do |k,v|
      %{#{k.to_s.camel_case.sub(/^(.{1,1})/) { |m| m.downcase }}="#{v}"} 
    end.join(' ')
  end
  
  alias_method :to_html_attributes, :to_xml_attributes
  
  # ==== Parameters
  # html_class<~to_s>::
  #   The HTML class to add to the :class key. The html_class will be
  #   concatenated to any existing classes.
  #
  # ==== Examples
  #   hash[:class] #=> nil
  #   hash.add_html_class!(:selected)
  #   hash[:class] #=> "selected"
  #   hash.add_html_class!("class1 class2")
  #   hash[:class] #=> "selected class1 class2"
  def add_html_class!(html_class)
    if self[:class]
      self[:class] = "#{self[:class]} #{html_class}"
    else
      self[:class] = html_class.to_s
    end
  end
  
  # Destructively convert all keys which respond_to?(:to_sym) to symbols. Works
  # recursively if given nested hashes.
  #
  # ==== Returns
  # Hash:: The newly converted hash.
  #
  # ==== Examples
  #   { 'one' => 1, 'two' => 2 }.symbolize_keys!
  #     #=> { :one => 1, :two => 2 }
  def symbolize_keys!
    each do |k,v| 
      sym = k.respond_to?(:to_sym) ? k.to_sym : k 
      self[sym] = Hash === v ? v.symbolize_keys! : v 
      delete(k) unless k == sym
    end
    self
  end
  
  # Converts all keys into string values. This is used during reloading to
  # prevent problems when classes are no longer declared.
  #
  # === Examples
  #   hash = { One => 1, Two => 2 }.proctect_keys!
  #   hash # => { "One" => 1, "Two" => 2 }
  def protect_keys!
    keys.each {|key| self[key.to_s] = delete(key) }
  end
  
  # Attempts to convert all string keys into Class keys. We run this after
  # reloading to convert protected hashes back into usable hashes.
  #
  # === Examples
  #   # Provided that classes One and Two are declared in this scope:
  #   hash = { "One" => 1, "Two" => 2 }.unproctect_keys!
  #   hash # => { One => 1, Two => 2 }
  def unprotect_keys!
    keys.each do |key| 
      (self[Object.full_const_get(key)] = delete(key)) rescue nil
    end
  end
  
  # Destructively and non-recursively convert each key to an uppercase string,
  # deleting nil values along the way.
  #
  # ==== Returns
  # Hash:: The newly environmentized hash.
  #
  # ==== Examples
  #   { :name => "Bob", :contact => { :email => "bob@bob.com" } }.environmentize_keys!
  #     #=> { "NAME" => "Bob", "CONTACT" => { :email => "bob@bob.com" } }
  def environmentize_keys!
    keys.each do |key|
      val = delete(key)
      next if val.nil?
      self[key.to_s.upcase] = val
    end
    self
  end  
end

require 'rexml/parsers/streamparser'
require 'rexml/parsers/baseparser'
require 'rexml/light/node'

# This is a slighly modified version of the XMLUtilityNode from
# http://merb.devjavu.com/projects/merb/ticket/95 (has.sox@gmail.com)
# It's mainly just adding vowels, as I ht cd wth n vwls :)
# This represents the hard part of the work, all I did was change the
# underlying parser.
class REXMLUtilityNode # :nodoc:
  attr_accessor :name, :attributes, :children

  def initialize(name, attributes = {})
    @name       = name.tr("-", "_")
    @attributes = undasherize_keys(attributes)
    @children   = []
    @text       = false
  end

  def add_node(node)
    @text = true if node.is_a? String
    @children << node
  end

  def to_hash
    if @text
      return { name => typecast_value( translate_xml_entities( inner_html ) ) }
    else
      #change repeating groups into an array
      # group by the first key of each element of the array to find repeating groups
      groups = @children.inject({}) { |s,e| (s[e.name] ||= []) << e; s }
      
      hash = {}
      groups.each do |key, values|
        if values.size == 1
          hash.merge! values.first
        else
          hash.merge! key => values.map { |element| element.to_hash[key] }
        end
      end
      
      # merge the arrays, including attributes
      hash.merge! attributes unless attributes.empty?
      
      { name => hash }
    end
  end

  # Typecasts a value based upon its type. For instance, if
  # +node+ has #type == "integer",
  # {{[node.typecast_value("12") #=> 12]}}
  #
  # ==== Parameters
  # value<String>:: The value that is being typecast.
  # 
  # ==== :type options
  # "integer":: 
  #   converts +value+ to an integer with #to_i
  # "boolean":: 
  #   checks whether +value+, after removing spaces, is the literal
  #   "true"
  # "datetime"::
  #   Parses +value+ using Time.parse, and returns a UTC Time
  # "date"::
  #   Parses +value+ using Date.parse
  #
  # ==== Returns
  # <Integer, true, false, Time, Date, Object>::
  #   The result of typecasting +value+.
  #
  # ==== Note
  # If +self+ does not have a "type" key, or if it's not one of the
  # options specified above, the raw +value+ will be returned.
  def typecast_value(value)
    return value unless attributes["type"]
    
    case attributes["type"]
      when "integer"  then value.to_i
      when "boolean"  then value.strip == "true"
      when "datetime" then ::Time.parse(value).utc
      when "date"     then ::Date.parse(value)
      else                 value
    end
  end

  # Convert basic XML entities into their literal values.
  #
  # ==== Parameters
  # value<~gsub>::
  #   An XML fragment.
  #
  # ==== Returns
  # <~gsub>::
  #   The XML fragment after converting entities.
  def translate_xml_entities(value)
    value.gsub(/&lt;/,   "<").
          gsub(/&gt;/,   ">").
          gsub(/&quot;/, '"').
          gsub(/&apos;/, "'").
          gsub(/&amp;/,  "&")
  end

  def undasherize_keys(params)
    params.keys.each do |key, value|
      params[key.tr("-", "_")] = params.delete(key)
    end
    params
  end

  def inner_html
    @children.join
  end

  def to_html
    "<#{name}#{attributes.to_xml_attributes}>#{inner_html}</#{name}>"
  end

  def to_s 
    to_html
  end
end

class ToHashParser # :nodoc:

  def self.from_xml(xml)
    stack = []
    parser = REXML::Parsers::BaseParser.new(xml)
    
    while true
      event = parser.pull
      case event[0]
      when :end_document
        break
      when :end_doctype, :start_doctype
        # do nothing
      when :start_element
        stack.push REXMLUtilityNode.new(event[1], event[2])
      when :end_element
        if stack.size > 1
          temp = stack.pop
          stack.last.add_node(temp)
        end
      when :text, :cdata
        stack.last.add_node(event[1]) unless event[1].strip.length == 0
      end
    end
    stack.pop.to_hash
  end
end