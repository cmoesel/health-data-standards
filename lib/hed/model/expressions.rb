require_relative 'hed-node'

module HeD
  module KnowledgeArtifact
    class Expression < HeDNode
      # right now, just a marker class.  Silly?
    end

    # UnaryExpression should be subclassed by Expression classes that extend ka:UnaryExpression.
    # It always contains a single attribute to which an array of values is mapped.
    # Assumption 1: Mappings aren't needed for unary expressions, so ignore them
    # Assumption 2: Defaults can't exist for unary expressions, so ignore them
    class UnaryExpression < Expression

      # Override 'from_node' to map all operands to the single attribute as an array
      #
      # @param [Nokogiri::XML::Node] node the root node to start the search at
      # @param [String] xpath the xpath expression to apply
      # @return [HeDNode] an instance of the UnaryExpression subclass
      def self.from_node(node, xpath=nil)
        node = node.at_xpath(xpath) if xpath
        return nil unless node
                
        operand = find_value(node, :operand, { :from => 'ka:operand' })
        self.new(operand)
      end
    end

    # NaryExpression should be subclassed by Expression classes that extend ka:NaryExpression.
    # If the class declares a single attribute, then an array of the values will be mapped to it.
    # If the class declares more than one attribute, the values will be assigned in order to each attribute.
    # Assumption 1: Mappings aren't needed for unary expressions, so ignore them
    # Assumption 2: Defaults can't exist for unary expressions, so ignore them
    class NaryExpression < Expression

      # Override 'from_node' to map operands to single attribute (as array) or multiple attributes.
      #
      # @param [Nokogiri::XML::Node] node the root node to start the search at
      # @param [String] xpath the xpath expression to apply
      # @return [HeDNode] an instance of the NaryExpression subclass
      def self.from_node(node, xpath=nil)
        node = node.at_xpath(xpath) if xpath
        return nil unless node

        operands = find_value(node, :operand, { :from => 'ka:operand', :as => [] })
        if @hed_attributes.length > 1
          self.new(*operands)
        else
          self.new(operands)
        end
      end
    end

    # The ExpressionRef knows how to find an expression by its name.
    class ExpressionRef < Expression

      # Override 'from_node' to find the expression node by name and then call 'from_node' on it.
      #
      # @param [Nokogiri::XML::Node] node the root node to start the search at
      # @param [String] xpath the xpath expression to apply
      # @return [HeDNode] an instance of an Expression subclass
      def self.from_node(node, xpath=nil)
        node = node.at_xpath(xpath) if xpath
        return nil unless node
        
        name = node['name']
        xpaths = [
          "ka:measureDocument/ka:externalData/ka:def[@name='#{name}']/ka:expression",
          "ka:measureDocument/ka:expressions/ka:def[@name='#{name}']/ka:expression",
          "ka:measureDocument/ka:measurePeriod[@name='#{name}']/ka:expression",
          "ka:measureDocument/ka:measureSubject[@name='#{name}']/ka:expression",
          "ka:measureDocument/ka:criteria/ka:criterion/ka:logic[@name='#{name}']/ka:expression",
          "ka:measureDocument/ka:measureObservation[@name='#{name}']/ka:expression",
        ]
        xpaths.each do |xp|
            exp_node = node.document.at_xpath(xp)
            return HeDNode.from_node(exp_node) if exp_node
        end
        # Never found it!
        puts "Failed to find expression for ExpressionRef name=#{name}"
        nil
      end
    end

    # The ParameterRef knows how to find an expression that is reference by a parameter name.
    class ParameterRef < Expression

      # Override 'from_node' to find the expression node by a parameter and then call 'from_node' on it.
      #
      # @param [Nokogiri::XML::Node] node the root node to start the search at
      # @param [String] xpath the xpath expression to apply
      # @return [HeDNode] an instance of an Expression subclass
      def self.from_node(node, xpath=nil)
        node = node.at_xpath(xpath) if xpath
        return nil unless node
                
        name = node['name']
        exp_node = node.document.at_xpath("ka:measureDocument/ka:externalData/ka:parameter[@name='#{name}']/ka:default")
        return HeDNode.from_node(exp_node) if exp_node if exp_node

        # Never found it!
        puts "Failed to find expression for ExpressionRef name=#{name}"
        nil
      end
    end

    class AllOf < NaryExpression
      hed_attr :args
    end

    class And < NaryExpression
      hed_attr :args
    end

    class AnyOf < NaryExpression
      hed_attr :args
    end

    class ClinicalRequest < Expression
      hed_attrs :cardinality, :data_type, :time_offset, :scope, :template_id, :id_property, :trigger_type,
                :codes, :date_range, :subject, :code_property, :date_property, :subject_property
      hed_attr :is_initial, :as => Boolean, :default => true
      hed_attr :use_value_sets, :as => Boolean, :default => false
      hed_attr :use_subsumption, :as => Boolean, :default => false
    end

    class Count < Expression
      hed_attrs :source, :path
    end

    class DateAdd < Expression
      hed_attrs :date, :granularity, :number_of_periods
    end

    class DateOf <UnaryExpression
      hed_attr :arg
    end

    class Distinct < Expression
      hed_attr :source
    end

    class Divide < NaryExpression
      hed_attrs :numerator, :denominator
    end

    class Equal < NaryExpression
      hed_attrs :arg_1, :arg_2
    end

    class Expand < UnaryExpression
      hed_attr :arg
    end

    class Filter < Expression
      hed_attrs :scope, :source, :condition
    end

    class ForEach < Expression
      hed_attrs :source, :element, :scope
    end

    class GreaterOrEqual < NaryExpression
      hed_attrs :arg_1, :arg_2
    end

    class In < NaryExpression
      hed_attrs :item, :set
    end

    class Interval < Expression
      hed_attr :begin
      hed_attr :end 
      hed_attr :begin_open, :as => Boolean, :default => false
      hed_attr :end_open, :as => Boolean, :default => false
    end

    class IntegerLiteral < Expression
      hed_attr :value, :as => Integer
    end

    class IsEmpty < UnaryExpression
      hed_attr :list
    end

    class IsNotEmpty < UnaryExpression
      hed_attr :list
    end

    class LessOrEqual < NaryExpression
      hed_attrs :arg_1, :arg_2
    end

    class Literal < Expression
      hed_attrs :value_type, :value
    end

    class Median < Expression
      hed_attrs :source, :path
    end

    class Not < UnaryExpression
      hed_attr :arg
    end

    class Property < Expression
      hed_attrs :path, :scope, :source
    end

    class StringLiteral < Expression
      hed_attr :value
    end

    class Subtract < NaryExpression
      hed_attrs :arg_1, :arg_2
    end

    class TimestampIntervalLiteral < Expression
      hed_attr :low, :from => 'ka:low/@value'
      hed_attr :high, :from => 'ka:high/@value'
      hed_attr :low_closed, :default => false, :as => Boolean
      hed_attr :high_closed, :default => false, :as => Boolean
    end

    class Union < NaryExpression
      hed_attr :args
    end

    class ValueSet < Expression
      hed_attrs :id, :version, :authority
    end
  end
end
