require 'archivist/models'
require 'representable'
require 'representable/json'

module Archivist
  module Representation
    class Document < Representable::Decorator
      include Representable::JSON
      
      property :identifier
      property :title
      property :date
      collection :languages
      collection :creators
    end
  end
end