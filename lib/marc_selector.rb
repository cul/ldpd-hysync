module MarcSelector
  # Selects the first marc field that matchest the given parameters.
  # See `all` method for usage details.
  def self.first(marc_record, field_number, filters = {})
    all(marc_record, field_number, filters).first
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
    marc_record.fields(field_number.to_s).select do |field|
      field_matches_filters(field, filters)
    end
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
end
