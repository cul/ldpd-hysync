module Hyacinth
  class Client
    def initialize(config)
      @config = config

      # Note: Base64.encode64 method can include newline characters, which messes things up.
      # That's why we're using Base64.strict_encode64 instead.
      @hyacinth_basic_auth_token = Base64.strict_encode64(@config['email'] + ':' + @config['password'])
    end

    def find_by_identifier(identifier, additional_search_params)
      search({
        per_page: 999999, # high limit so we find all records with the given identifier
        search_field: 'search_identifier_sim',
        q: identifier,
      }.merge(additional_search_params))
    end

    def find_by_pid(pid)
      results = search({
        per_page: 1,
        search_field: 'pid',
        q: pid
      })
      results.length == 1 ? results.first : nil
    end

    def search(search_params = {})
      # Step 1: Get PIDs and CLIO IDs for all publish targets that have CLIO IDs
      search_url = "#{@config['url']}/digital_objects/search.json"
      post_params = {
      	search: search_params
      }

      begin
        results = JSON.parse(RestClient::Request.execute(
            method: :post,
            url: search_url,
            timeout: 60,
            payload: post_params,
            headers: {Authorization: "Basic #{@hyacinth_basic_auth_token}"}
          )
        )
      rescue RestClient::ExceptionWithResponse => err
        raise "Error: Received response '#{err.message}' for Hyacinth search request."
      end

      results['results'].map{|result| JSON.parse(result['digital_object_data_ts'])}
    end

    def create_new_record(digital_object_data, publish = false)
      response = Hyacinth::Client::Response.new
      begin
        json_response = JSON.parse(RestClient::Request.execute(
          method: :post,
          url: "#{@config['url']}/digital_objects.json",
          timeout: 60,
          payload: {'digital_object_data_json' => JSON.generate(digital_object_data.merge({publish: publish}))},
          headers: {Authorization: "Basic #{@hyacinth_basic_auth_token}"}
        ).body)
        if json_response['success'] != true
          response.errors << "Error creating record. Details: #{json_response['errors'].inspect}"
        end
        response
      rescue RestClient::ExceptionWithResponse => err
        response.errors << "Error: Received response '#{err.message}' for Hyacinth record create request."
      end
      response
    end

    def update_existing_record(pid, digital_object_data, publish = false)
      response = Hyacinth::Client::Response.new
      begin
        json_response = JSON.parse(RestClient::Request.execute(
          method: :put,
          url: "#{@config['url']}/digital_objects/#{pid}.json",
          timeout: 60,
          payload: {'digital_object_data_json' => JSON.generate(digital_object_data.merge({publish: publish}))},
          headers: {Authorization: "Basic #{@hyacinth_basic_auth_token}"}
        ).body)
        # TODO: Eventually use response code instead of checking for success value
        if json_response['success'] != true
          response.errors << "Error updating record #{pid}. Details: #{json_response['errors'].inspect}"
        end
      rescue RestClient::ExceptionWithResponse => err
        response.errors << "Error: Received response '#{err.message}' for Hyacinth record update request for #{pid}"
      end
      response
    end

    # Downloads the entire set of collection controlled terms from Hyacinth.
    # TODO: Stop using this download in Hyacinth 3, since the new version of
    # URI Service will allow us to search for terms by any custom field, so
    # we won't need to download all terms.
    def generate_collection_clio_ids_to_uris_map
      clio_ids_to_term_uris = {}

      per_page = 50
      page = 1
      loop do
        collection_data_response = JSON.parse(
          RestClient::Request.execute(
            method: :get,
            max_redirects: 0, # Don't automatically follow redirects
            # The 'collection' controlled vocabulary has ID 20. We'll be able to use strings in the next version of URI Service.
            url: "#{@config['url']}/controlled_vocabularies/20/terms.json?page=#{page}&per_page=#{per_page}",
            timeout: 60,
            headers: {Authorization: "Basic #{@hyacinth_basic_auth_token}"}
          )
        )

        collection_data_response['terms'].each do |term|
          if term['clio_id']
            clio_ids_to_term_uris[term['clio_id']] = term['uri']
          end
        end

        break unless collection_data_response['more_available']
        page += 1
      end

      clio_ids_to_term_uris
    end

    def create_controlled_term(term_data)
      Rails.logger.debug("Creating new controlled term: " + term_data.inspect)
      JSON.parse(RestClient::Request.execute(
        method: :post,
        url: "#{@config['url']}/terms.json",
        timeout: 60,
        payload: {
          'term' => term_data
        },
        headers: {Authorization: "Basic #{@hyacinth_basic_auth_token}"}
      ).body)
    end

    class Response
      attr_accessor :errors
      def initialize()
        @errors = []
      end

      def errors?
        errors.length > 0
      end

      def success?
        !errors?
      end
    end
  end
end
