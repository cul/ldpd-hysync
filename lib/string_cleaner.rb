module StringCleaner
  def self.trailing_punctuation(string)
    string.sub(/[,.]+$/, '')
  end

  def self.trailing_comma(string)
    string.sub(/,$/, '')
  end
end
