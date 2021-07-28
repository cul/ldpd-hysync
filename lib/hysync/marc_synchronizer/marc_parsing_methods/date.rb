module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Date
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_date
        end

        def add_date(marc_record, holdings_marc_records, mapping_ruleset)
          date_type = extract_date_type(marc_record, mapping_ruleset)
          date1, date2 = extract_date1_and_date2(marc_record)
          add_appropriate_date_fields(date_type, date1, date2, marc_record, mapping_ruleset)
        end

        # Converts ['u', 'x', '?'] in dates to 'X'
        # Converts 'XXXX' to '' (because 'XXXX' offers no helpful information).
        def normalize_date(date_string)
          normalized = date_string&.tr('ux?', 'X')
          normalized == 'XXXX' ? '' : normalized
        end

        # Extracts the date1 and date2 values from the MARC 008 field
        # @return [date1, date2]
        def extract_date1_and_date2(marc_record)
          field = MarcSelector.first(marc_record, '008')
          return [nil, nil] if field.nil?
          date1 = field.value[7..10].strip
          date2 = field.value[11..14].strip
          date1 = nil if date1 == ''
          date2 = nil if date2 == ''
          [date1, date2]
        end

        def extract_date_type(marc_record, mapping_ruleset)
          return MarcSelector.first(marc_record, '008').value[6]
        end

        def add_date_created(date1, date2, date_type, is_keydate)
          return if date1.nil? && date2.nil?
          dynamic_field_data['date_created'] ||= []
          dynamic_field_data['date_created'] << {
            'date_created_start_value' => normalize_date(date1),
            'date_created_end_value' => normalize_date(date2),
            'date_created_key_date' => is_keydate,
            'date_created_type' => date_type == 'q' ? 'questionable' : nil # only 'questionable' is a valid date type in MODS
          }
        end

        def add_date_issued(date1, date2, date_type, is_keydate)
          return if date1.nil? && date2.nil?
          dynamic_field_data['date_issued'] ||= []
          dynamic_field_data['date_issued'] << {
            'date_issued_start_value' => normalize_date(date1),
            'date_issued_end_value' => normalize_date(date2),
            'date_issued_key_date' => is_keydate,
            'date_issued_type' => date_type == 'q' ? 'questionable' : nil # only 'questionable' is a valid date type in MODS
          }
        end

        def extract_textual_date(marc_record, mapping_ruleset)
          if ['oral_history'].include?(mapping_ruleset)
            field = MarcSelector.first(marc_record, 245, f: true)
            return StringCleaner.trailing_punctuation_and_whitespace(field['f']) unless field.nil?
            return nil
          end

          # Default
          field = MarcSelector.first(marc_record, 260, c: true)
          return StringCleaner.trailing_punctuation_and_whitespace(field['c']) unless field.nil?
          field = MarcSelector.first(marc_record, 264, indicator2: 1, c: true) if field.nil?
          return StringCleaner.trailing_punctuation_and_whitespace(field['c']) unless field.nil?
          field = MarcSelector.first(marc_record, 264, indicator2: 3, c: true) if field.nil?
          return StringCleaner.trailing_punctuation_and_whitespace(field['c']) unless field.nil?
          field = MarcSelector.first(marc_record, 264, indicator2: 0, c: true) if field.nil?
          return StringCleaner.trailing_punctuation_and_whitespace(field['c']) unless field.nil?
          field = MarcSelector.first(marc_record, 245, f: true)
          return StringCleaner.trailing_punctuation_and_whitespace(field['f']) unless field.nil?

          nil
        end

        def add_date_created_textual(textual_date)
          return if textual_date.nil?
          dynamic_field_data['date_created_textual'] ||= []
          dynamic_field_data['date_created_textual'] << {
            'date_created_textual_value' => textual_date
          }
        end

        def add_date_issued_textual(textual_date)
          return if textual_date.nil?
          dynamic_field_data['date_issued_textual'] ||= []
          dynamic_field_data['date_issued_textual'] << {
            'date_issued_textual_value' => textual_date
          }
        end

        def add_appropriate_date_fields(date_type, date1, date2, marc_record, mapping_ruleset)
          # Important rule. If this MARC record has ANY 245 $f value, then we treat any Date Issued values
          # as if they were Date Created valued.
          has_245_f = MarcSelector.first(marc_record, '245', f: true).present?

          textual_date = extract_textual_date(marc_record, mapping_ruleset)

          # For annual reports, replace default values if values are found in alternate field
          if mapping_ruleset == 'annual_reports'
            fields = (
              MarcSelector.all(marc_record, 362, indicator1: 0, a: true) +
              MarcSelector.all(marc_record, 362, indicator1: 1, a: true)
            )
            # If we found any textual date values from the 362 fields,
            # use those values and set the earlier textual_date value to nil
            # so that it is ignored.
            textual_date = nil if fields.present?

            fields.each do |field|
              add_date_created_textual(StringCleaner.trailing_punctuation_and_whitespace(field['a']))
            end
          end

          # Rules below are from discussion between Melanie and Eric.
          # See: https://docs.google.com/spreadsheets/d/1hwOL_N4QNSAB7UiMfvUeT7NiGoWyByqUibKkiFau6FA
          case date_type
          when 'c', 'd', 'i', 'k', 'm', 'n', 'q', 'u'
            # Date Issued (start of date range); Date Issued (end of date range).
            #c - Continuing resource currently published.
            #d - Continuing resource ceased publication.
            #i - Inclusive dates of collection.
            #k - Range of years of bulk of collection.
            #m - Multiple dates.
            #n - Dates unknown.
            #q - Questionable date.
            #u - Continuing resource status unknown.
            args = date1, date2, date_type, true
            if has_245_f
              add_date_created(*args) # presence of 245 $f means put Date Issued value into Date Created
              add_date_created_textual(textual_date)
            else
              add_date_issued(*args)
              add_date_issued_textual(textual_date)
            end
          when 'e'
            #e - Detailed date. Date Issued (Single date). Ignore date2.
            args = date1, nil, date_type, true
            if has_245_f
              add_date_created(*args) # presence of 245 $f means put Date Issued value into Date Created
              add_date_created_textual(textual_date)
            else
              add_date_issued(*args)
              add_date_issued_textual(textual_date)
            end
          when 'p'
            # p - Date of distribution/release/issue and production/recording session when different.
            # If mapping_ruleset == 'video', set date2 as date_cteated since other date is too uncertain to use (e.g. vague "19uu" date)
            # If date1 and date2 are the same, only record a dateCreated entry for that single (same) date.
            # If the dates are different, we can record both dateIssued (for the first date) and dateCreated (for the second date).
            if mapping_ruleset == 'video'
              add_date_created(date2, nil, date_type, true)
            elsif date1 == date2
              add_date_created(date1, nil, date_type, true)
              add_date_created_textual(textual_date)
            else
              add_date_created(date2, nil, date_type, false)
              add_date_issued(date1, nil, date_type, true) # we'll make the issued date the key date here
              add_date_created_textual(textual_date)
            end
          when 'r'
            #r - Reprint/reissue date and original date. Only keep the second date and record it as dateCreated.
            add_date_created(date2, nil, date_type, true)
            add_date_created_textual(textual_date)
          when 's'
            #s - single known date/probable date. First date is Date Issued (Single date).
            args = date1, nil, date_type, true
            if has_245_f
              add_date_created(*args) # presence of 245 $f means put Date Issued value into Date Created
              add_date_created_textual(textual_date)
            else
              add_date_issued(*args)
              add_date_issued_textual(textual_date)
            end
          when 't'
            #t - Publication date and copyright date. Use date1 for Date Issued (Single date). Ignore the copyright date in Date2.
            # It may mean that our structured date doesn't exactly match the $c dates, but the publication year seems more important.
            args = date1, nil, date_type, true
            if has_245_f
              add_date_created(*args) # presence of 245 $f means put Date Issued value into Date Created
              add_date_created_textual(textual_date)
            else
              add_date_issued(*args)
              add_date_issued_textual(textual_date)
            end
          end
        end

      end
    end
  end
end
