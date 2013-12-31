require 'faraday'
require 'faraday_middleware'
require 'archivist/client/filters'
require 'archivist/representations'

module Archivist
  module Client
    # This is the primary interface of the gem.
    # Example Usage:
    #   require 'archive-client'
    #   # Create an Archivist client:
    #   client = Archivist::Client::Base.new
    #   # Search for the books you're interested in:
    #   books = client.search(:start_year => 1500, :end_year => 1510)
    #   # Download them:
    #   books.each do |book|
    #     puts book.download
    #   end
    class Base
      DEFAULT_CONNECTION = Faraday.new(url: 'http://archive.org') do |faraday|
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.request  :url_encoded             # form-encode POST params
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
      attr_reader :conn
      attr_accessor :filters # will be a Filters.new object

      # filter_opts can be provided here, or when search is called.
      # filters_opts are:
      #   :language   => if *any* search opts provided there.
      #   :start_year => search opts takes precedence when provided there.
      def initialize(opts = {}, filter_opts = {})
        @filters = Archivist::Client::Filters.new(filter_opts)
        @opts = {
          page: 1,
          rows: 50
        }.merge(opts)

        @conn = DEFAULT_CONNECTION
      end

      def search(opts = {})
        Model::QueryResponse.new.tap do |qr|
          response = @conn.get('/advancedsearch.php', params(opts))
          Representation::QueryResponse.new(qr).from_json(response.body)
        end
      end

      private

      def query(opts)
        @filters.update!(opts)
        @filters.to_query
      end

      def params(opts = {})
        {
          q: query(opts),
          fl: %w(identifier title creator date language mediattype),
          sort: ['date asc'],
          output: 'json'
        }.merge(@opts).merge(opts)
      end

    end
  end
end
