require_relative '../../../test_helper'
require_relative '../../../../lib/hed/model/document'
require_relative '../../../../lib/hed/model/expressions'

class HedExpressionsTest < Test::Unit::TestCase
  include HeD::KnowledgeArtifact
  
  def setup
    @doc = parse_hed_string(File.open("test/fixtures/hed/fragments/expressions.xml").read)
  end

  def parse_hed_string(s)
    doc = Nokogiri::XML(s)
    doc.root.add_namespace_definition('ka', 'urn:hl7-org:knowledgeartifact:r1')
    doc.root.add_namespace_definition('xsi', 'http://www.w3.org/2001/XMLSchema-instance')
    doc
  end

  def lookup(name)
    @doc.at_xpath("ka:measureDocument/ka:externalData/ka:def[@name='#{name}']/ka:expression")
  end

  def from_fragment(klass, postfix = nil)
    name = klass.name.demodulize
    name = "#{name}_#{postfix}" if postfix
    klass.from_node(lookup(name))
  end

  def test_clinical_request_everything
    exp = from_fragment(ClinicalRequest, 'Everything')
    exp.cardinality.must_equal 'Multiple'
    exp.data_type.must_equal 'vmr:Encounter'
    exp.code_property.must_equal 'encounterCode'
    exp.date_property.must_equal 'effectiveDateTime.low'
    exp.subject_property.must_equal 'evaluatedPersonId'
    exp.use_value_sets.must_equal true
    exp.use_subsumption.must_equal true
    exp.scope.must_equal 'ED'
    exp.template_id.must_equal 'abc'
    exp.id_property.must_equal 'xyz'
    exp.trigger_type.must_equal 'DataElementAdded'
    exp.is_initial.must_equal false
    exp.codes.must_be_instance_of ValueSet
    exp.date_range.must_be_instance_of TimestampIntervalLiteral
    exp.subject.must_be_instance_of ClinicalRequest
    exp.time_offset.must_be_instance_of IntegerLiteral
  end

  def test_clinical_request_minimal
    exp = from_fragment(ClinicalRequest, 'Minimal')
    exp.cardinality.must_equal 'Single'
    exp.data_type.must_equal 'vmr:Patient'
    exp.use_value_sets.must_equal false
    exp.use_subsumption.must_equal false
    exp.is_initial.must_equal true
  end

  def test_count
    exp = from_fragment(Count)
    exp.source.must_be_instance_of Distinct
    exp.path.must_equal 'value'
  end

  def test_date_add
    exp = from_fragment(DateAdd)
    exp.date.must_be_instance_of Property
    exp.granularity.must_be_instance_of Literal
    exp.number_of_periods.must_be_instance_of IntegerLiteral
  end

  def test_distinct
    exp = from_fragment(Distinct)
    exp.source.must_be_instance_of Union
  end

  def test_divide
    exp = from_fragment(Divide)
    exp.numerator.must_be_instance_of IntegerLiteral
    exp.numerator.value.must_equal 150
    exp.denominator.must_be_instance_of IntegerLiteral
    exp.denominator.value.must_equal 3
  end

  def test_equal
    exp = from_fragment(Equal)
    exp.arg_1.must_be_instance_of Property
    exp.arg_2.must_be_instance_of StringLiteral
  end

  def test_expression_ref
    refs = {
      'ExternalData' => 'ABCD',
      'Expressions' => 'EFG',
      'MeasurePeriod' => 'HIJK',
      'MeasureSubject' => 'LMNOP',
      'Criterion' => 'QRS',
      'MeasureObservation' => 'TUV'
    }

    refs.each_pair do | target, expected_value |
      exp = from_fragment(ExpressionRef, target)
      exp.value.must_equal expected_value
    end
  end

  def test_parameter_ref
    exp = from_fragment(ParameterRef)
    exp.value.must_equal 'WXYZ'
  end

  def test_filter
    exp = from_fragment(Filter)
    exp.source.must_be_instance_of ClinicalRequest
    exp.condition.must_be_instance_of Equal
    exp.scope.must_equal 'abc'
  end

  def test_greater_or_equal_10_20
    exp = from_fragment(GreaterOrEqual)
    exp.arg_1.must_be_instance_of IntegerLiteral
    exp.arg_1.value.must_equal 10
    exp.arg_2.must_be_instance_of IntegerLiteral
    exp.arg_2.value.must_equal 20
  end

  def test_for_each
    exp = from_fragment(ForEach)
    exp.source.must_be_instance_of Union
    exp.element.must_be_instance_of Subtract
    exp.scope.must_equal 'xyz'
  end

  def test_in
    exp = from_fragment(In)
    exp.item.must_be_instance_of Property
    exp.set.must_be_instance_of ValueSet
  end

  def test_integer_literal
    exp = from_fragment(IntegerLiteral)
    exp.value.must_equal 42
  end

  def test_interval_everything
    exp = from_fragment(Interval, 'Everything')
    exp.begin.must_be_instance_of Property
    exp.end.must_be_instance_of DateAdd
    exp.begin_open.must_equal true
    exp.end_open.must_equal true
  end

  def test_interval_minimal
    exp = from_fragment(Interval, 'Minimal')
    exp.begin.must_be_nil
    exp.end.must_be_nil
    exp.begin_open.must_equal false
    exp.end_open.must_equal false
  end

  def test_less_or_equal_10_20
    exp = from_fragment(LessOrEqual)
    exp.arg_1.must_be_instance_of IntegerLiteral
    exp.arg_1.value.must_equal 10
    exp.arg_2.must_be_instance_of IntegerLiteral
    exp.arg_2.value.must_equal 20
  end

  def test_literal
    exp = from_fragment(Literal)
    exp.value_type.must_equal 'DateGranularity'
    exp.value.must_equal 'Hour'
  end

  def test_median
    exp = from_fragment(Median)
    exp.source.must_be_instance_of Union
    exp.path.must_equal 'value'
  end

  def test_property_everything
    exp = from_fragment(Property, 'Everything')
    exp.scope.must_equal 'Numbers'
    exp.path.must_equal 'value'
    exp.source.must_be_instance_of IntegerLiteral
  end

  def test_property_minimal
    exp = from_fragment(Property, 'Minimal')
    exp.scope.must_equal 'ED'
    exp.path.must_equal 'dischargeStatus'
    exp.source.must_be_nil
  end

  def test_string_literal
    exp = from_fragment(StringLiteral)
    exp.value.must_equal 'Hello World'
  end

  def test_subtract
    exp = from_fragment(Subtract)
    exp.arg_1.must_be_instance_of IntegerLiteral
    exp.arg_1.value.must_equal 20
    exp.arg_2.must_be_instance_of IntegerLiteral
    exp.arg_2.value.must_equal 10
  end

  def test_timestamp_interval_literal_everything
    exp = from_fragment(TimestampIntervalLiteral, 'Everything')
    exp.low.must_equal '20130101'
    exp.high.must_equal '20140101'
    exp.low_closed.must_equal true
    exp.high_closed.must_equal true
  end

  def test_timestamp_interval_literal_minimal
    exp = from_fragment(TimestampIntervalLiteral, 'Minimal')
    exp.low.must_equal '20130101'
    exp.high.must_equal '20140101'
    exp.low_closed.must_equal false
    exp.high_closed.must_equal false
  end

  def test_value_set
    exp = from_fragment(ValueSet)
    exp.id.must_equal '2.16.840.1.113883.3.666.5.1146'
    exp.version.must_equal '20130401'
    exp.authority.must_equal 'VSAC'
  end

  def test_single_arg_nary_subclasses
    class_map = {AllOf => :args, And => :args, AnyOf => :args, Union => :args}

    # first test that an empty expression causes an empty array
    class_map.each_pair do | klass, attr_name |
      xml = parse_hed_string(%Q{
        <root xmlns="urn:hl7-org:knowledgeartifact:r1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <expression xsi:type="#{klass.name.demodulize}" />
        </root>
      })

      exp = klass.from_node(xml, "ka:root/ka:expression")
      exp.send(attr_name).must_equal([])
    end

    # then test that multiple arguments are correctly mapped to the array
    class_map.each_pair do | klass, attr_name |
      xml = parse_hed_string(%Q{
        <root xmlns="urn:hl7-org:knowledgeartifact:r1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <expression xsi:type="#{klass.name.demodulize}">
            <operand xsi:type="IntegerLiteral" value="1" />
            <operand xsi:type="IntegerLiteral" value="2" />
            <operand xsi:type="IntegerLiteral" value="3" />
          </expression>
        </root>
      })

      exp = klass.from_node(xml, "ka:root/ka:expression")
      args = exp.send(attr_name)

      args.length.must_equal 3
      args.each_with_index do | arg, i |
        arg.value.must_equal(i+1)
      end
    end
  end

  def test_unary_subclasses
    class_map = {DateOf => :arg, Expand => :arg, IsEmpty => :list, IsNotEmpty => :list, Not => :arg}

    # first test that no expression causes a nil argument
    class_map.each_pair do | klass, attr_name |
      xml = parse_hed_string(%Q{
        <root xmlns="urn:hl7-org:knowledgeartifact:r1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <expression xsi:type="#{klass.name.demodulize}" />
        </root>
      })

      exp = klass.from_node(xml, "ka:root/ka:expression")
      exp.send(attr_name).must_be_nil
    end

    # then test that multiple arguments are correctly mapped to the array
    class_map.each_pair do | klass, attr_name |
      xml = parse_hed_string(%Q{
        <root xmlns="urn:hl7-org:knowledgeartifact:r1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <expression xsi:type="#{klass.name.demodulize}">
            <operand xsi:type="IntegerLiteral" value="42" />
          </expression>
        </root>
      })

      exp = klass.from_node(xml, "ka:root/ka:expression")
      exp.send(attr_name).value.must_equal 42
    end
  end
end
