require_relative '../../../test_helper'
require_relative '../../../../lib/hed/parser/parser'

class ParseHedTest < Test::Unit::TestCase
  
  def setup
    @cms32v3_contents = File.open("test/fixtures/hed/measures/CMS32v3.xml").read
  end
  
  def test_basic_parse
    
    parsed = HeD::Parser.parse(@cms32v3_contents)
    parsed.metadata.title.must_equal "Median Time from ED Arrival to ED Departure for Discharged ED Patients"
    
  end
  
end
