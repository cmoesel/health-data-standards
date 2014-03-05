require_relative '../model/document'

module HeDr1
  
  # Class representing a Health eDecisions (HeD) measure document
  class MeasureDocument
      
    # Create a new HeD::KnowledgeArtifact::Document instance by parsing the file at the supplied path
    # @param [String] hed_contents the text of the HeD document
    def initialize(hed_contents)
      @doc = MeasureDocument.parse(hed_contents)
      @doc.root.add_namespace_definition('ka', 'urn:hl7-org:knowledgeartifact:r1')
      @doc.root.add_namespace_definition('xsi', 'http://www.w3.org/2001/XMLSchema-instance')
    end

    # Parse the XML document in the supplied contents
    # @param [String] hed_contents the text of the HeD document
    # @return [Nokogiri::XML::Document]
    def self.parse(hed_contents)
      Nokogiri::XML(hed_contents)
    end

    # Convert the XML Document to the HeD model
    # @return [HeD::KnowledgeArtifact::MeasureDocument]
    def to_model
      HeD::KnowledgeArtifact::MeasureDocument.from_node(@doc, 'ka:measureDocument')
    end
  end

end
