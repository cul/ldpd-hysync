module MarcSelector
  # Selects the first marc field that matchest the given parameters.
  # See `all` method for usage details.
  def self.first(marc_record, field_number, filters = {})
    all(marc_record, field_number, filters).first
  end

  def self.each_with_index(marc_record, field_number, filters = {}, &block)
    all_with_index(marc_record, field_number, filters).each &block
  end

  def self.each(marc_record, field_number, filters = {}, &block)
    all(marc_record, field_number, filters).each &block
  end

  # Selects all marc fields that match the given parameters.
  # @param marc_record [MARC::Record] marc record object
  # @param field_number [String] Marc field number to select.
  # @param filters [Hash] An optional map of filters, with keys
  #        like :indicator1, :indicator2, or a field number,
  #        and associated values that you wish to match on.
  #        Supply a value of true to check for the presence of
  #        a non-indicator field.
  #        Example filter: {indicator1: 0, indicator2: 1, b: 'something', c: true}
  # @return [Array] found results, or an empty array
  def self.all(marc_record, field_number, filters = {})
    all_with_index(marc_record, field_number, filters).map { |field, _ix| field }
  end

  # Selects all marc fields that match the given parameters.
  # @return [Array] tuples of marc fields and indexes by field number, or an empty array
  def self.all_with_index(marc_record, field_number, filters = {})
    ix = -1
    marc_record.fields(field_number.to_s).map do |field|
      [field, (ix += 1)]
    end.select do |field, _ix|
      field_matches_filters(field, filters)
    end
  end

  def self.at(marc_record, field_number, index = 0)
    (marc_record.fields(field_number.to_s) || [])[index]
  end

  # @return true if the field matches all given filters
  def self.field_matches_filters(field, filters)
    filters.each do |filter, filter_value|
      case filter
      when :indicator1
        return false unless field.indicator1 == filter_value.to_s
      when :indicator2
        return false unless field.indicator2 == filter_value.to_s
      else
        # filter is a subfield
        if filter_value == true
          # check for presence of subfield
          return false if field[filter.to_s].nil?
        else
          # check for specific subfield value
          return false unless field[filter.to_s] == filter_value.to_s
        end
      end
    end
    true
  end

  # For the given field, concatenates (with a space) all values in the given subfields.
  # Blank or nil subfields are skipped.
  # @param field [MARC::Field] Field to process
  # @param subfield_keys [Array] Array of subfield keys to concatenate
  # @clean [Boolean] Whether or not to clean trailing whitespace and punctuation.
  def self.concat_subfield_values(field, subfield_keys, clean = true)
    val = subfield_keys.map { |subfield_key| field[subfield_key].present? ? field[subfield_key] : nil }.compact.join(' ')
    clean ? StringCleaner.trailing_punctuation_and_whitespace(val) : val
  end
end
