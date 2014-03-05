require_relative 'hed-node'
require_relative 'expressions'

module HeD
  module KnowledgeArtifact

    class VersionedIdentifier < HeDNode
      hed_attr :id, :from => '@root'
      hed_attr :version
    end

    class Metadata < HeDNode
      hed_attr :ids, :from => 'ka:identifiers/ka:identifier', :as => [VersionedIdentifier]
      hed_attr :schema_id, :from => 'ka:schemaIdentifier', :as => VersionedIdentifier
      hed_attr :data_models, :from => 'ka:dataModels/ka:modelReference/ka:referencedModel/@value', :as => []
      hed_attr :title, :from => 'ka:title/@value'
      hed_attr :description, :from => 'ka:description/@value'
    end

    class MeasureSubject < HeDNode
      hed_attr :id, :from => '@subjectId'
      hed_attr :subject, :from => 'ka:expression'
    end

    class Criterion < HeDNode
      hed_attr :logic, :from => 'ka:logic/ka:expression'
      hed_attr :role, :from => 'ka:criterionRole/@value'
    end

    class MeasureDocument < HeDNode
      hed_attr :metadata
      hed_attr :measure_type, :from => 'ka:measureType/@value'
      hed_attr :measure_period, :from => 'ka:measurePeriod/ka:expression'
      hed_attr :measure_subject
      hed_attr :criteria, :from => 'ka:criteria/ka:criterion', :as => [Criterion]
      hed_attr :measure_observation, :from => 'ka:measureObservation/ka:expression'
      hed_attr :measure_score
      hed_attr :scores
    end

  end
end