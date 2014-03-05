require_relative 'document'

module HeD
  class Parser
        
    def self.parse(hed_contents)
      HeDr1::MeasureDocument.new(hed_contents).to_model
    end

  end
  
end