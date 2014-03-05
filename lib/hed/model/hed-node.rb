module HeD
  module KnowledgeArtifact

    # The HeDNode class provides several convenient features for succinctly declaring classes for Hed objects.
    # The general concept is such:
    #   - Subclasses of HeDNode can declare their attributes, including optional HeD XML mappings, types, and defaults
    #   - HedNode automatically creates attributes and accessors for each attribute
    #   - HedNode exposes a constructor and from_hash method for creating new objects (supporting default values)
    #   - HedNode exposes a from_node method for creating an object from an HeD XML Node
    #   - For attributes that do not have mappings declared, HeDNode will guess the mappings based on attribute names
    #   - By default, two HeDNode objects are == if all of their attributes are ==
    class HeDNode

      # Define class instance variable for attributes so each subclass has its own value
      class << self
        # The mapping of attribute names to HeD nodes and attributes.
        #
        # @return [Hash]
        def hed_attributes
          @hed_attributes ||= {}
        end
      end

      # Create an array of HeDNodes by parsing the nodes that match the xpath expression.  This method
      # will use the class's attributes, defaults, mappings, and types to parse the HeD XML.
      #
      # @param [Nokogiri::XML::Node] node the root node to start the search at
      # @param [String] xpath the xpath expression to apply
      # @return [Array]
      def self.from_nodes(node, xpath=nil)
        nodes = xpath ? node.xpath(xpath) : node
        return nil unless nodes

        nodes = nodes.to_a if nodes.kind_of? Nokogiri::XML::NodeSet
        nodes = [nodes] unless nodes.kind_of? Array
        nodes.map { |n| self.from_node(n) }
      end

      # Create an HeDNode by parsing the node that matches the xpath expression.  This method will use
      # the class's attributes, defaults, mappings, and types to parse the HeD XML.
      #
      # @param [Nokogiri::XML::Node] node the root node to start the search at
      # @param [String] xpath the xpath expression to apply
      # @return [HeDNode] an instance of the HeDNode subclass
      def self.from_node(node, xpath=nil)
        node = node.at_xpath(xpath) if xpath
        return nil unless node

        if (self == HeDNode)
          hed_class = discover_type(node['xsi:type'], node.name)
          return hed_class.from_node(node) if hed_class
          nil
        end
        
        args = []
        hed_attributes.each_pair do |att, options|
          args.push(find_value(node, att, options))
        end
        self.new(*args)
      end

      # Create an HeDNode by from a passed in Hash.  If attributes are not included in the passed in hash,
      # then that attribute will be set to the default value (if available) or nil.
      #
      # @param [Hash] hash a hash containing the attributes to instantiate with
      # @return [HeDNode] an instance of the HeDNode subclass
      def self.from_hash(hash)
        args = []
        hed_attributes.each_pair do |att, options|
          val = hash.has_key?(att) ? hash[att] : options[:default]
          args.push(val)
        end
        self.new(*args)
      end

      # Constructor for a HeDNode subclass.  The arguments should be in the same order as the class's
      # attributes were declared.  Trailing arguments are optional if defaults have been provided for them.
      #
      # @param [*Object] the arguments in the same order as the class's declared attributes
      def initialize(*args)
        self.class.hed_attributes.each_with_index do |e, i|
          val = args.length > i ? args[i] : e[1][:default]
          self.send("#{e[0]}=", val)
        end
      end

      # Override == such that two objects are == if all attribute values are ==
      #
      # @param [HeDNode] other the other object to compare
      def ==(other)
        return true if other.equal?(self)
        return false unless other.instance_of?(self.class)
        self.class.hed_attributes.keys.each do |att|
          # puts "MISMATCH ON #{self.class.name} -> #{att}: (#{self.send(att)} vs #{other.send(att)})" unless self.send(att) == other.send(att)
          return false unless self.send(att) == other.send(att)
        end
        true
      end

      protected

      # Subclass declarations use the 'hed_attr' method to declare an attribute for a class, along with
      # its optional mappings and defaults.  For example:
      #
      #   hed_attr :low_closed, :from => 'ka:lowClosed/@value', :as => Boolean, :default => false
      #
      # At a minimum, the attribute name needs to be provided.  In this case, the HeD XML mapping will
      # be guessed from the attribute name (searching for XML attributes and child nodes), the type
      # will be guessed from the attribute name (trying to match against an HeD class name, falling back
      # to String), and the default will be nil.  For example:
      #
      #   hed_attr :metadata
      #
      # An attribute and accessor will be created for the passed in attribute.  The class's constructor
      # will expect arguments in the attribute order.
      #
      # @param [Symbol] attribute the attribute name as a symbol
      # @param [Hash] options the options including mapping (:as) and default (:default)
      def self.hed_attr(attribute, options={})
        hed_attributes[attribute] = options
        self.send(:attr_accessor, attribute)
      end

      # Subclass declarations use the 'hed_attrs' method to declare multiple attributes for a class,
      # along with their optional mappings and defaults.  For all intents and purposes, it acts the
      # same as 'hed_attr', but requires options to be passed in as a hash value for the attribute name.
      # This allows you to mix name-only and name-plus-options in one statement.  For example:
      #
      #   hed_attrs :kettle_manufacturer, :kettle_model, :kettle_color => { :default => black }
      #
      # @param [*Symbol or *Hash] attributes the list of attributes to declare for the class
      def self.hed_attrs(*attributes)
        attributes.each do |att|
          if (att.class == Hash)
            att.each do |key, val| 
              hed_attr(key, val)
            end
          else
            hed_attr(att)
          end
        end
      end

      # Find the value for an attribute, given the root node and an optional set of options.
      # 
      # @param [Nokogiri::XML::Node] node the root node that contains the attribute and value
      # @param [Symbol] attribute the attribute to find the value for
      # @param [Hash] options the set of options to assist in finding and parsing the value
      def self.find_value(node, attribute, options={})
        options = hed_attributes[attribute] || options

        nodes = nil
        if options[:from]
          nodes = node.xpath(options[:from])
        else
          name = attribute.to_s.camelize(:lower)
          nodes = node.xpath("ka:#{name}", "@#{name}")
        end

        val = nil
        if (options[:as].instance_of?(Array))
          val = convert_values(nodes, attribute, options[:as].first)
          val = options[:default] if val.empty? && options.has_key?(:default)
        else
          val = convert_values(nodes.slice(0,1) || [], attribute, options[:as]).first
          val = options[:default] if val.nil?
        end     

        val   
      end

      private

      # Convert a set of nodes to values of the target class type (inferring type if necessary)
      #
      # @param [Nokogiri::XML::NoeSet] nodes the set of nodes to convert to values
      # @param [Symbol] attribute the attribute for which we are converting the value
      # @param [Class] target_class the target class to convert to
      def self.convert_values(nodes, attribute, target_class=nil)
        nodes.map do |n|
          klass = target_class || self.discover_type(n['xsi:type'], attribute.to_s.camelize, n.name)

          val = nil
          if (klass.nil?)
            val = n.inner_text if n.child.text? || n.instance_of?(Nokogiri::XML::Attr)
            puts "Don't know how to convert #{n}" unless val
          elsif klass <= HeDNode
            val = klass.from_node(n)
          elsif klass <= Integer
            val = n.inner_text.to_i
          elsif klass <= Boolean
            val = (n.inner_text == 'true')
          elsif klass <= String
            val = n.inner_text
          end

          val
        end
      end

      # Given a list of possible names, attempts to find a valid HeD class that matches.
      #
      # @param [*String] the list of names to use when trying to find a matching HeD class
      # @return [HeDNode] the matching HeDNode or nil if none is found
      def self.discover_type(*names)
        names.compact.map { |n | n.gsub(/^([a-z])/) { $1.capitalize }}.each do | name |
          klass = "HeD::KnowledgeArtifact::#{name}".safe_constantize
          return klass if klass
        end
        nil
      end
    end

  end
end