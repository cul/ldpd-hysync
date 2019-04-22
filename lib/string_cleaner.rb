module StringCleaner
  def self.trailing_punctuation(string)
    string.sub(/[,.:]+$/, '').strip
  end

  def self.trailing_comma(string)
    string.sub(/,$/, '').strip
  end
end
