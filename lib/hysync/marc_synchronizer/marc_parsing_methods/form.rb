module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Form
        extend ActiveSupport::Concern

        included do
          register_parsing_method :add_form
        end

        def add_form(marc_record, holdings_marc_records, mapping_ruleset)
          # We skip form for ldeotechnical because that collection uses genre instead of form
          return if mapping_ruleset == 'ldeotechnical'

          dynamic_field_data['form'] ||= []
          extract_form_terms(marc_record, mapping_ruleset).each do |form_term|
            dynamic_field_data['form'] << {
              'form_term' => form_term
            }
          end
        end

        def extract_form_terms(marc_record, mapping_ruleset)
          form_terms = []
          if mapping_ruleset == 'oral_history'
            form_terms << { 'uri' => 'http://id.loc.gov/authorities/genreForms/gf2011026431' } # oral histories
          elsif mapping_ruleset == 'gumbymicrofilm'
            form_terms << { 'uri' => 'http://vocab.getty.edu/aat/300026690' } # albums
          end

          leader_bytes_6_and_7 = marc_record.leader[6..7]
          case leader_bytes_6_and_7
          when 'am', # Language material, Monograph/Item
            'aa' # Language material, Monographic component part
            form_terms << { 'uri' => 'http://id.loc.gov/vocabulary/graphicMaterials/tgm001221' } # books
          when 'as', # Language material, Serial
            'ab' # Language material, Serial component part
            form_terms << { 'uri' => 'http://id.loc.gov/vocabulary/graphicMaterials/tgm007641' } # periodicals
          when 'em', # Cartographic material, Monograph/Item
            'fm', # Manuscript cartographic material, Monograph/Item
            'ea', # Cartographic material, Monographic component part
            'fa' # Manuscript cartographic material, Monographic component part
            form_terms << { 'uri' => 'http://id.loc.gov/vocabulary/graphicMaterials/tgm006261' } # maps
          when 'id', # Sound recording, Subunit
            'im', # Sound recording, monograph/item
            'ic' # Sound recording, Collection
            form_terms << { 'uri' => 'http://id.loc.gov/vocabulary/graphicMaterials/tgm009874' } # sound recordings
          when 'gm', # Video recording, Monograph/item
            'gd' # Video recording, Collection
            form_terms << { 'uri' => 'http://vocab.getty.edu/aat/300028682' } # video recordings
          when 'kd' # Two-dimensional nonprojectable graphic, Subunit
            form_terms << { 'uri' => 'http://id.loc.gov/vocabulary/graphicMaterials/tgm007779' } # pictures
          when 'km', # Two-dimensional nonprojectable graphic, Monograph/Item
            'ac', # Language material, Collection
            'pc', # Mixed materials, Collection
            'kc' # Two-dimensional nonprojectable graphic, Collection
            form_terms << { 'uri' => 'http://vocab.getty.edu/aat/300028881' } # ephemera
          when 'rm' # Three-dimensional artifact or naturally occurring object, Monograph/Item
            form_terms << { 'uri' => 'http://id.loc.gov/vocabulary/graphicMaterials/tgm007159' } # objects
          when 'tc', # Manuscript language material, Collection
            'tm' # Manuscript language material, Monograph/Item
            form_terms << { 'uri' => 'http://id.loc.gov/authorities/subjects/sh85080672.html' } # manuscripts
          when 'cm' # Notated music, Monograph/Item
            form_terms << { 'uri' => 'http://id.loc.gov/authorities/genreForms/gf2014026952' } # music
          when 'jm' # Musical sound recording, Monograph/Item
            form_terms << { 'uri' => 'http://id.loc.gov/authorities/genreForms/gf2014026952' } # music
            form_terms << { 'uri' => 'http://id.loc.gov/vocabulary/graphicMaterials/tgm009874' } # sound recordings
          else
            # If we cannot map the MARC form pair AND this record doesn't
            # already have another form (from a mapping_rule, etc.), then
            # add an error.
            self.errors << "Unmapped MARC form pair (leader bytes 6 and 7) for clio id #{marc_record['001'].value}: #{leader_bytes_6_and_7}" unless form_terms.present?
          end

          form_terms
        end
      end
    end
  end
end
