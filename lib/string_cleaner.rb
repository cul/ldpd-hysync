module StringCleaner
  def self.trailing_punctuation_and_whitespace(string)
    return nil if string.nil?
    stripped_string = string.strip
    return stripped_string if stripped_string.ends_with?('...')
    stripped_string.sub(/[,.:\/ ]+$/, '').strip
  end
end
