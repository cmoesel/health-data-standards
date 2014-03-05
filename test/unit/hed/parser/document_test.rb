require_relative '../../../test_helper'
require_relative '../../../../lib/hed/parser/document'

class HedDocumentTest < Test::Unit::TestCase
  include HeD::KnowledgeArtifact
  
  def setup
    @cms32v3_contents = File.open("test/fixtures/hed/measures/CMS32v3.xml").read
  end
  
  def test_parse_cms32v3
    
    doc = HeDr1::MeasureDocument.new(@cms32v3_contents).to_model

    doc.metadata.must_equal(Metadata.from_hash(
      :ids => [VersionedIdentifier.new('CMS32', '3')],
      :schema_id => VersionedIdentifier.new('urn:hl7-org:v3:knowledgeartifact:r1', '1'),
      :data_models => ['urn:hl7-org:v3:vmr:r2'],
      :title => 'Median Time from ED Arrival to ED Departure for Discharged ED Patients'))
    
    doc.measure_type.must_equal 'ContinuousVariable'
    
    doc.measure_period.must_equal(TimestampIntervalLiteral.new('20130101', '20140101'))
    
    expected_subject = ClinicalRequest.from_hash(
      :cardinality => 'Single',
      :data_type => 'vmr:Patient')
    doc.measure_subject.must_equal(MeasureSubject.new('id', expected_subject))

    initial_population = ClinicalRequest.from_hash(
      :cardinality => 'Multiple',
      :data_type => 'vmr:Encounter',
      :codes => ValueSet.new('', '20130614', 'VSAC'),
      :date_range => TimestampIntervalLiteral.new('20130101', '20140101'),
      :code_property => 'encounterCode',
      :date_property => 'effectiveDateTime.low',
      :subject_property => 'evaluatedPersonId')
    doc.criteria[0].must_equal(Criterion.new(initial_population, 'InitialPopulation'))

    measure_population = AllOf.new([
      Filter.from_hash(:scope => 'ED', :source => initial_population, :condition => And.new([
        IsEmpty.new(Filter.from_hash(
          :scope => 'Inpatient',
          :source => ClinicalRequest.from_hash(
            :cardinality => 'Multiple',
            :data_type => 'vmr:Encounter',
            :code_property => 'encounterCode',
            :date_property => 'effectiveDateTime.low',
            :subject_property => 'evaluatedPersonId',
            :codes => ValueSet.new('', '20130614', 'VSAC')),
          :condition => LessOrEqual.new(
            Property.new('effectiveDateTime.low', 'Inpatient', nil),
            DateAdd.from_hash(
              :date => Property.new('effectiveDateTime.high', 'ED', nil),
              :granularity => Literal.new('DateGranularity', 'Hour'),
              :number_of_periods => IntegerLiteral.new(6))))),
        Not.new(In.new(
          Property.new('dischargeStatus', 'ED', nil),
          ValueSet.new('2.16.840.1.113883.3.666.5.1146', '20130401', 'VSAC')))
      ]))
    ])
    doc.criteria[1].must_equal(Criterion.new(measure_population, 'MeasurePopulation'))

    stratum_1 = initial_population
    doc.criteria[2].must_equal(Criterion.new(stratum_1, 'Stratifier'))

    stratum_2 = Filter.from_hash(
      :scope => 'ED',
      :source => initial_population,
      :condition => IsNotEmpty.new(Filter.from_hash(
        :scope => 'Diagnosis',
        :condition => In.new(
          Property.new('effectiveTime.low', 'Diagnosis', nil),
          Property.new('effectiveTime', 'ED', nil)))))
    doc.criteria[3].must_equal(Criterion.new(stratum_2, 'Stratifier'))

    stratum_3 = Filter.from_hash(
      :scope => 'ED',
      :source => initial_population,
      :condition => IsNotEmpty.new(
        Filter.from_hash(
          :scope => 'Transfer',
          :condition => LessOrEqual.new(
            Property.new('effectiveTime.low', 'Transfer', nil),
            DateAdd.from_hash(
              :date => Property.new('effectiveTime.high', 'ED', nil),
              :granularity => Literal.new('DateGranularity', 'Hour'),
              :number_of_periods => IntegerLiteral.new(6))))))
    doc.criteria[4].must_equal(Criterion.new(stratum_3, 'Stratifier'))

    stratum_4 = Filter.from_hash(
      :scope => 'ED',
      :source => initial_population,
      :condition => And.new([
        IsEmpty.new(Filter.from_hash(
          :scope => 'Diagnosis',
          :condition => In.new(
            Property.new('effectiveTime.low', 'Diagnosis', nil),
            Property.new('effectiveTime', 'ED', nil)))),
        IsEmpty.new(Filter.from_hash(
          :scope => 'Transfer',
          :condition => LessOrEqual.new(
            Property.new('effectiveTime.low', 'Transfer', nil),
            DateAdd.from_hash(
              :date => Property.new('effectiveTime.high', 'ED', nil),
              :granularity => Literal.new('DateGranularity', 'Hour'),
              :number_of_periods => IntegerLiteral.new(6)))))
      ]))
    doc.criteria[5].must_equal(Criterion.new(stratum_4, 'Stratifier'))
    
    length_of_stay = ForEach.from_hash(
      :source => measure_population,
      :element => Subtract.new(
        Property.from_hash(:path => 'effectiveDateTime.high'),
        Property.from_hash(:path => 'effectiveDateTime.low')))
    doc.measure_observation.must_equal(length_of_stay)

    doc.measure_score.must_equal(Median.new(Expand.new(length_of_stay)))
  end
  
end
