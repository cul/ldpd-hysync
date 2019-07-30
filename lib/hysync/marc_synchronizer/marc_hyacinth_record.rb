module Hysync
  module MarcSynchronizer
    class MarcHyacinthRecord
      include Hysync::MarcSynchronizer::MarcParsingMethods
      include Hysync::MarcSynchronizer::MarcParsingMethods::ClioIdentifier
      include Hysync::MarcSynchronizer::MarcParsingMethods::ArchiveOrgIdentifier
      include Hysync::MarcSynchronizer::MarcParsingMethods::Collection
      include Hysync::MarcSynchronizer::MarcParsingMethods::Marc005LastModified
      include Hysync::MarcSynchronizer::MarcParsingMethods::Project
      include Hysync::MarcSynchronizer::MarcParsingMethods::PublishTargets
      include Hysync::MarcSynchronizer::MarcParsingMethods::Abstract
      include Hysync::MarcSynchronizer::MarcParsingMethods::CopyrightNote
      include Hysync::MarcSynchronizer::MarcParsingMethods::Date
      include Hysync::MarcSynchronizer::MarcParsingMethods::Extent
      include Hysync::MarcSynchronizer::MarcParsingMethods::Form
      include Hysync::MarcSynchronizer::MarcParsingMethods::Genre
      include Hysync::MarcSynchronizer::MarcParsingMethods::Language
      include Hysync::MarcSynchronizer::MarcParsingMethods::Location
      include Hysync::MarcSynchronizer::MarcParsingMethods::Name
      include Hysync::MarcSynchronizer::MarcParsingMethods::Note
      include Hysync::MarcSynchronizer::MarcParsingMethods::BiographicalNote
      include Hysync::MarcSynchronizer::MarcParsingMethods::PlaceOfOrigin
      include Hysync::MarcSynchronizer::MarcParsingMethods::Provenance
      include Hysync::MarcSynchronizer::MarcParsingMethods::Publisher
      include Hysync::MarcSynchronizer::MarcParsingMethods::SubjectGeographic
      include Hysync::MarcSynchronizer::MarcParsingMethods::SubjectName
      include Hysync::MarcSynchronizer::MarcParsingMethods::SubjectTopic
      include Hysync::MarcSynchronizer::MarcParsingMethods::SubjectTitle
      include Hysync::MarcSynchronizer::MarcParsingMethods::Title
      include Hysync::MarcSynchronizer::MarcParsingMethods::AlternativeTitle
      include Hysync::MarcSynchronizer::MarcParsingMethods::TypeOfResource
      include Hysync::MarcSynchronizer::MarcParsingMethods::RestrictionOnAccess
      include Hysync::MarcSynchronizer::MarcParsingMethods::Url

      # include Hysync::MarcSynchronizer::MarcParsingMethods::Group # TODO: For Hyaicnth 3

      attr_reader :digital_object_data
      attr_reader :mapping_ruleset
      attr_reader :errors

      def initialize(marc_record = nil, holdings_marc_records = [], default_digital_object_data = {}, voyager_client = nil)
        @errors = []
        @digital_object_data = default_digital_object_data
        hyacinth_flag = MarcSelector.first(marc_record, 965, {a: '965hyacinth'})
        @mapping_ruleset = hyacinth_flag['b'] if hyacinth_flag
        # ensure that dynamic_field_data key is present, because later code depends on it
        @digital_object_data['dynamic_field_data'] ||= {}

        # parse marc and add data to digital_object_data
        add_marc_data(marc_record, holdings_marc_records, voyager_client) unless marc_record.nil?
      end

      def dynamic_field_data
        @digital_object_data['dynamic_field_data'] ||= {}
      end

      def clio_id
        dynamic_field_data['clio_identifier'].first['clio_identifier_value']
      end

      def marc_005_last_modified
        dynamic_field_data['marc_005_last_modified'].first['marc_005_last_modified_value']
      end

      # Merges data from this marc record into the underlying digital_object_data fields
      def add_marc_data(marc_record, holdings_marc_records, voyager_client = nil)
        begin
          self.class.registered_parsing_methods.each do |method_name|
            args = [method_name, marc_record, holdings_marc_records, @mapping_ruleset]
            if self.method(method_name).arity == -4 # optional voyager client arg
              args << voyager_client
            end
            self.send(*args)
          end
        rescue StandardError => e
          self.errors << "An unhandled error was encountered while parsing record #{self.clio_id}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
        end
      end
    end
  end
end
