# frozen_string_literal: true

class Hysync::FolioApiClient < FolioApiClient
  def self.instance(reload: false)
    @instance = self.new(self.default_folio_api_client_configuration) if @instance.nil? || reload
    @instance
  end

  # Retrieves information about all registered FOLIO locations and returns a
  # Hash mapping location ids to location records. This method caches results after the first call and uses the
  # cache for subsequent calls.  To bypass the cache, pass `reload: true` as an argument.
  def locations(reload: false)
    return @locations if @locations.present? && !reload

    total_number_of_locations = self.get('/locations', { limit: 0 })['totalRecords']
    all_locations = self.get(
      '/locations', { limit: total_number_of_locations }
    )['locations']

    @locations = {}
    all_locations.each do |location|
      @locations[location['id']] = location
    end

    @locations
  end

  def self.default_folio_api_client_configuration # rubocop:disable Metrics/AbcSize
    FolioApiClient::Configuration.new(
      url: Rails.application.config.folio[:url],
      username: Rails.application.config.folio[:username],
      password: Rails.application.config.folio[:password],
      tenant: Rails.application.config.folio[:tenant],
      timeout: Rails.application.config.folio[:timeout]
    )
  end

  # Finds a single record by bib id
  # @return [MARC::Record] The MARC record associated with the given id.
  def find_by_bib_id(bib_id)
    source_record = self.find_source_record(instance_record_hrid: bib_id)
    return nil if source_record.nil?

    MARC::Record.new_from_hash(source_record['parsedRecord']['content'])
  end

  def holdings_for_instance_hrid(instance_hrid)
    self.get(
      '/search/instances', { expandAll: true, limit: 1, query: "hrid==#{instance_hrid}" }
    )['instances']&.first&.fetch('holdings') || []
  end
end
