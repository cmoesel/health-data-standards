require_relative '../../../test_helper'
require_relative '../../../../lib/hed/model/hed-node'

class HedNodeTest < Test::Unit::TestCase
  include HeD::KnowledgeArtifact

  def setup
    xml = %Q{
      <root xmlns="urn:hl7-org:knowledgeartifact:r1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <testThing abc="123" xyz="789" alphabetsRock="true">
          <aBoolean>true</aBoolean>
          <anEmbeddedBoolean value="false"/>
          <anInteger>42</anInteger>
          <anEmbeddedInteger value="24"/>
          <aString>Hello World!</aString>
          <anEmbeddedString value="Hello Again!"/>
          <anObject><howdy>folks!</howdy></anObject>
          <stringArray>apples</stringArray>
          <stringArray>oranges</stringArray>
          <stringArray>bananas</stringArray>
          <embeddedStringArray vegetable="green beans"/>
          <embeddedStringArray vegetable="green peas"/>
          <embeddedStringArray vegetable="carrots"/>
        </testThing>
        <emptyThing />
      </root>
    }

    @doc = Nokogiri::XML(xml)
    @doc.root.add_namespace_definition('ka', 'urn:hl7-org:knowledgeartifact:r1')
    @doc.root.add_namespace_definition('xsi', 'http://www.w3.org/2001/XMLSchema-instance')
  end

  class SmallTestThing < HeDNode
    hed_attr :howdy, :from => 'ka:howdy', :as => String, :default => 'people!'
  end
  
  class FullTestThing < HeDNode
    hed_attr :abc, :from => '@abc', :as => String, :default => '456'
    hed_attr :xyz, :from => '@xyz', :as => Integer, :default => 456
    hed_attr :alphabets_rock, :from => '@alphabetsRock', :as => Boolean, :default => false
    hed_attr :a_boolean, :from => 'ka:aBoolean', :as => Boolean, :default => false
    hed_attr :an_embedded_boolean, :from => 'ka:anEmbeddedBoolean/@value', :as => Boolean, :default => true
    hed_attr :an_integer, :from => 'ka:anInteger', :as => Integer, :default => 999
    hed_attr :an_embedded_integer, :from => 'ka:anEmbeddedInteger/@value', :as => Integer, :default => 888
    hed_attr :a_string, :from => 'ka:aString', :as => String, :default => 'Goodbye!'
    hed_attr :an_embedded_string, :from => 'ka:anEmbeddedString/@value', :as => String, :default => 'L8R!'
    hed_attr :an_object, :from => 'ka:anObject', :as => SmallTestThing, :default => SmallTestThing.new()
    hed_attr :string_array, :from => 'ka:stringArray', :as => [String], :default => ['pears', 'grapefruits']
    hed_attr :embedded_string_array, :from => 'ka:embeddedStringArray/@vegetable', :as => [String], :default => ['corn', 'kale']
  end

  class FullTestThing2 < HeDNode
    hed_attrs :abc => { :from => '@abc', :as => String, :default => '456' },
              :xyz => { :from => '@xyz', :as => Integer, :default => 456 },
              :alphabets_rock => { :from => '@alphabetsRock', :as => Boolean, :default => false },
              :a_boolean => { :from => 'ka:aBoolean', :as => Boolean, :default => false },
              :an_embedded_boolean => { :from => 'ka:anEmbeddedBoolean/@value', :as => Boolean, :default => true },
              :an_integer => { :from => 'ka:anInteger', :as => Integer, :default => 999 },
              :an_embedded_integer => { :from => 'ka:anEmbeddedInteger/@value', :as => Integer, :default => 888 },
              :a_string => { :from => 'ka:aString', :as => String, :default => 'Goodbye!' },
              :an_embedded_string => { :from => 'ka:anEmbeddedString/@value', :as => String, :default => 'L8R!' },
              :an_object => { :from => 'ka:anObject', :as => SmallTestThing, :default => SmallTestThing.new() },
              :string_array => { :from => 'ka:stringArray', :as => [String], :default => ['pears', 'grapefruits'] },
              :embedded_string_array => { :from => 'ka:embeddedStringArray/@vegetable', :as => [String], :default => ['corn', 'kale'] }
  end

  class InferredTestThing < HeDNode
    hed_attr :abc
    hed_attr :xyz, :as => Integer
    hed_attr :alphabets_rock, :as => Boolean
    hed_attr :a_boolean, :as => Boolean
    hed_attr :an_embedded_boolean, :from => 'ka:anEmbeddedBoolean/@value', :as => Boolean
    hed_attr :an_integer, :as => Integer
    hed_attr :an_embedded_integer, :from => 'ka:anEmbeddedInteger/@value', :as => Integer
    hed_attr :a_string
    hed_attr :an_embedded_string, :from => 'ka:anEmbeddedString/@value'
    hed_attr :an_object, :as => SmallTestThing
    hed_attr :string_array, :as => []
    hed_attr :embedded_string_array, :from => 'ka:embeddedStringArray/@vegetable', :as => []
  end

  class InferredTestThing2 < HeDNode
    hed_attrs :abc, :a_string, :xyz => { :as => Integer }, :alphabets_rock => { :as => Boolean }, :a_boolean => { :as => Boolean },
              :an_embedded_boolean => { :from => 'ka:anEmbeddedBoolean/@value', :as => Boolean }, :an_integer => { :as => Integer },
              :an_embedded_integer => { :from => 'ka:anEmbeddedInteger/@value', :as => Integer },
              :an_embedded_string => { :from => 'ka:anEmbeddedString/@value' }, :an_object => { :as => SmallTestThing },
              :string_array => { :as => [] }, :embedded_string_array => { :from => 'ka:embeddedStringArray/@vegetable', :as => [] }
  end

  class InferredTestThing3 < HeDNode
    hed_attrs :abc, :a_string, :xyz => { :as => Integer }, :alphabets_rock => { :as => Boolean }, :a_boolean => { :as => Boolean },
              :an_integer => { :as => Integer }, :an_object => { :as => SmallTestThing }, :string_array => { :as => [] }
    hed_attr :an_embedded_boolean, :from => 'ka:anEmbeddedBoolean/@value', :as => Boolean
    hed_attr :an_embedded_integer, :from => 'ka:anEmbeddedInteger/@value', :as => Integer
    hed_attr :an_embedded_string, :from => 'ka:anEmbeddedString/@value'
    hed_attr :embedded_string_array, :from => 'ka:embeddedStringArray/@vegetable', :as => []
  end

  def test_full_definition
    t = FullTestThing.from_node(@doc, 'ka:root/ka:testThing')
    t.abc.must_equal '123'
    t.xyz.must_equal 789
    t.alphabets_rock.must_equal true
    t.a_boolean.must_equal true
    t.an_embedded_boolean.must_equal false
    t.an_integer.must_equal 42
    t.an_embedded_integer.must_equal 24
    t.a_string.must_equal 'Hello World!'
    t.an_embedded_string.must_equal 'Hello Again!'
    t.an_object.must_equal SmallTestThing.new('folks!')
    t.string_array.must_equal ['apples', 'oranges', 'bananas']
    t.embedded_string_array.must_equal ['green beans', 'green peas', 'carrots']
  end

  def test_full_definition_with_hed_attrs
    t = FullTestThing2.from_node(@doc, 'ka:root/ka:testThing')
    t.abc.must_equal '123'
    t.xyz.must_equal 789
    t.alphabets_rock.must_equal true
    t.a_boolean.must_equal true
    t.an_embedded_boolean.must_equal false
    t.an_integer.must_equal 42
    t.an_embedded_integer.must_equal 24
    t.a_string.must_equal 'Hello World!'
    t.an_embedded_string.must_equal 'Hello Again!'
    t.an_object.must_equal SmallTestThing.new('folks!')
    t.string_array.must_equal ['apples', 'oranges', 'bananas']
    t.embedded_string_array.must_equal ['green beans', 'green peas', 'carrots']
  end

  def test_inferred_definition
    t = InferredTestThing.from_node(@doc, 'ka:root/ka:testThing')
    t.abc.must_equal '123'
    t.xyz.must_equal 789
    t.alphabets_rock.must_equal true
    t.a_boolean.must_equal true
    t.an_embedded_boolean.must_equal false
    t.an_integer.must_equal 42
    t.an_embedded_integer.must_equal 24
    t.a_string.must_equal 'Hello World!'
    t.an_embedded_string.must_equal 'Hello Again!'
    t.an_object.must_equal SmallTestThing.new('folks!')
    t.string_array.must_equal ['apples', 'oranges', 'bananas']
    t.embedded_string_array.must_equal ['green beans', 'green peas', 'carrots']
  end

  def test_inferred_definition_with_hed_attrs
    t = InferredTestThing2.from_node(@doc, 'ka:root/ka:testThing')
    t.abc.must_equal '123'
    t.xyz.must_equal 789
    t.alphabets_rock.must_equal true
    t.a_boolean.must_equal true
    t.an_embedded_boolean.must_equal false
    t.an_integer.must_equal 42
    t.an_embedded_integer.must_equal 24
    t.a_string.must_equal 'Hello World!'
    t.an_embedded_string.must_equal 'Hello Again!'
    t.an_object.must_equal SmallTestThing.new('folks!')
    t.string_array.must_equal ['apples', 'oranges', 'bananas']
    t.embedded_string_array.must_equal ['green beans', 'green peas', 'carrots']
  end

  def test_inferred_definition_with_mix
    t = InferredTestThing3.from_node(@doc, 'ka:root/ka:testThing')
    t.abc.must_equal '123'
    t.xyz.must_equal 789
    t.alphabets_rock.must_equal true
    t.a_boolean.must_equal true
    t.an_embedded_boolean.must_equal false
    t.an_integer.must_equal 42
    t.an_embedded_integer.must_equal 24
    t.a_string.must_equal 'Hello World!'
    t.an_embedded_string.must_equal 'Hello Again!'
    t.an_object.must_equal SmallTestThing.new('folks!')
    t.string_array.must_equal ['apples', 'oranges', 'bananas']
    t.embedded_string_array.must_equal ['green beans', 'green peas', 'carrots']
  end

  def test_full_definition_defaults
    t = FullTestThing.from_node(@doc, 'ka:root/ka:emptyThing')
    t.abc.must_equal '456'
    t.xyz.must_equal 456
    t.alphabets_rock.must_equal false
    t.a_boolean.must_equal false
    t.an_embedded_boolean.must_equal true
    t.an_integer.must_equal 999
    t.an_embedded_integer.must_equal 888
    t.a_string.must_equal 'Goodbye!'
    t.an_embedded_string.must_equal 'L8R!'
    t.an_object.must_equal SmallTestThing.new('people!')
    t.string_array.must_equal ['pears', 'grapefruits']
    t.embedded_string_array.must_equal ['corn', 'kale']
  end

  def test_full_definition_defaults_with_hed_attrs
    t = FullTestThing2.from_node(@doc, 'ka:root/ka:emptyThing')
    t.abc.must_equal '456'
    t.xyz.must_equal 456
    t.alphabets_rock.must_equal false
    t.a_boolean.must_equal false
    t.an_embedded_boolean.must_equal true
    t.an_integer.must_equal 999
    t.an_embedded_integer.must_equal 888
    t.a_string.must_equal 'Goodbye!'
    t.an_embedded_string.must_equal 'L8R!'
    t.an_object.must_equal SmallTestThing.new('people!')
    t.string_array.must_equal ['pears', 'grapefruits']
    t.embedded_string_array.must_equal ['corn', 'kale']
  end

  def test_constructor
    t = FullTestThing.new('123', 789, true, true, false, 42, 24, 'Hello World!', 'Hello Again!', SmallTestThing.new('folks!'),
      ['apples', 'oranges', 'bananas'], ['green beans', 'green peas', 'carrots'])
    t.abc.must_equal '123'
    t.xyz.must_equal 789
    t.alphabets_rock.must_equal true
    t.a_boolean.must_equal true
    t.an_embedded_boolean.must_equal false
    t.an_integer.must_equal 42
    t.an_embedded_integer.must_equal 24
    t.a_string.must_equal 'Hello World!'
    t.an_embedded_string.must_equal 'Hello Again!'
    t.an_object.must_equal SmallTestThing.new('folks!')
    t.string_array.must_equal ['apples', 'oranges', 'bananas']
    t.embedded_string_array.must_equal ['green beans', 'green peas', 'carrots']
  end

  def test_constructor_defaults
    t = FullTestThing.new()
    t.abc.must_equal '456'
    t.xyz.must_equal 456
    t.alphabets_rock.must_equal false
    t.a_boolean.must_equal false
    t.an_embedded_boolean.must_equal true
    t.an_integer.must_equal 999
    t.an_embedded_integer.must_equal 888
    t.a_string.must_equal 'Goodbye!'
    t.an_embedded_string.must_equal 'L8R!'
    t.an_object.must_equal SmallTestThing.new('people!')
    t.string_array.must_equal ['pears', 'grapefruits']
    t.embedded_string_array.must_equal ['corn', 'kale']
  end

  def test_from_hash
    t = FullTestThing.from_hash({
      :abc => '123',
      :xyz => 789,
      :alphabets_rock => true,
      :a_boolean => true,
      :an_embedded_boolean => false,
      :an_integer => 42,
      :an_embedded_integer => 24,
      :a_string => 'Hello World!',
      :an_embedded_string => 'Hello Again!',
      :an_object => SmallTestThing.new('folks!'),
      :string_array => ['apples', 'oranges', 'bananas'],
      :embedded_string_array => ['green beans', 'green peas', 'carrots']
    })

    t.abc.must_equal '123'
    t.xyz.must_equal 789
    t.alphabets_rock.must_equal true
    t.a_boolean.must_equal true
    t.an_embedded_boolean.must_equal false
    t.an_integer.must_equal 42
    t.an_embedded_integer.must_equal 24
    t.a_string.must_equal 'Hello World!'
    t.an_embedded_string.must_equal 'Hello Again!'
    t.an_object.must_equal SmallTestThing.new('folks!')
    t.string_array.must_equal ['apples', 'oranges', 'bananas']
    t.embedded_string_array.must_equal ['green beans', 'green peas', 'carrots']
  end

  def test_from_sparse_hash
    t = FullTestThing.from_hash({
      :alphabets_rock => true,
      :an_embedded_integer => 24,
      :string_array => ['apples', 'oranges', 'bananas']
    })

    # from hash
    t.alphabets_rock.must_equal true
    t.an_embedded_integer.must_equal 24
    t.string_array.must_equal ['apples', 'oranges', 'bananas']

    # defaults for the rest
    t.abc.must_equal '456'
    t.xyz.must_equal 456
    t.a_boolean.must_equal false
    t.an_embedded_boolean.must_equal true
    t.an_integer.must_equal 999
    t.a_string.must_equal 'Goodbye!'
    t.an_embedded_string.must_equal 'L8R!'
    t.an_object.must_equal SmallTestThing.new('people!')
    t.embedded_string_array.must_equal ['corn', 'kale']
  end

  def test_from_hash_no_defaults
    t = InferredTestThing.from_hash({})
    t.abc.must_be_nil
    t.xyz.must_be_nil
    t.alphabets_rock.must_be_nil
    t.a_boolean.must_be_nil
    t.an_embedded_boolean.must_be_nil
    t.an_integer.must_be_nil
    t.an_embedded_integer.must_be_nil
    t.a_string.must_be_nil
    t.an_embedded_string.must_be_nil
    t.an_object.must_be_nil
    t.string_array.must_be_nil
    t.embedded_string_array.must_be_nil
  end

  def test_attr_accessors
    t = InferredTestThing.from_hash({})
    t.abc = '321'
    t.abc.must_equal '321'
    t.xyz = 987
    t.xyz.must_equal 987
    t.alphabets_rock = false
    t.alphabets_rock.must_equal false
    t.a_boolean = false
    t.a_boolean.must_equal false
    t.an_embedded_boolean = true
    t.an_embedded_boolean.must_equal true
    t.an_integer = 55
    t.an_integer.must_equal 55
    t.an_embedded_integer = 44
    t.an_embedded_integer.must_equal 44
    t.a_string = 'Hello Dallas!'
    t.a_string.must_equal 'Hello Dallas!'
    t.an_embedded_string = 'Hello Cleveland!'
    t.an_embedded_string.must_equal 'Hello Cleveland!'
    t.an_object = SmallTestThing.new('earthlings!')
    t.an_object.must_equal SmallTestThing.new('earthlings!')
    t.string_array = ['grapes', 'peaches']
    t.string_array.must_equal ['grapes', 'peaches']
    t.embedded_string_array = ['cauliflower']
    t.embedded_string_array.must_equal ['cauliflower']
  end

  def test_equality
    t1 = FullTestThing.from_hash({
      :abc => '123',
      :xyz => 789,
      :alphabets_rock => true,
      :a_boolean => true,
      :an_embedded_boolean => false,
      :an_integer => 42,
      :an_embedded_integer => 24,
      :a_string => 'Hello World!',
      :an_embedded_string => 'Hello Again!',
      :an_object => SmallTestThing.new('folks!'),
      :string_array => ['apples', 'oranges', 'bananas'],
      :embedded_string_array => ['green beans', 'green peas', 'carrots']
    })

    t2 = FullTestThing.from_hash({
      :abc => '123',
      :xyz => 789,
      :alphabets_rock => true,
      :a_boolean => true,
      :an_embedded_boolean => false,
      :an_integer => 42,
      :an_embedded_integer => 24,
      :a_string => 'Hello World!',
      :an_embedded_string => 'Hello Again!',
      :an_object => SmallTestThing.new('folks!'),
      :string_array => ['apples', 'oranges', 'bananas'],
      :embedded_string_array => ['green beans', 'green peas', 'carrots']
    })

    t1.must_equal t2
    t2.string_array.push('kiwi')
    t1.wont_equal t2
    t1.string_array.push('kiwi')
    t1.must_equal t2
    t1.alphabets_rock = false
    t1.wont_equal t2
  end
end