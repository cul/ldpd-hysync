require 'rails_helper'

describe StringCleaner do
  context ".trailing_punctuation_and_whitespace" do
    it "removes characters as expected" do
      {
        'The title.' => 'The title',
        'The title,' => 'The title',
        'The title:' => 'The title',
        'The title/' => 'The title',
        'The title  .  ' => 'The title',
        '    The title  .  ' => 'The title'
      }.each do |pre, post|
        expect(described_class.trailing_punctuation_and_whitespace(pre)).to eq(post)
      end
    end
    it "doesn't remove trailing ellipsis" do
      {
        'The title...' => 'The title...',
        'The title... ' => 'The title...',
        '  The title...  ' => 'The title...',
        'The title ... ' => 'The title ...'
      }.each do |pre, post|
        expect(described_class.trailing_punctuation_and_whitespace(pre)).to eq(post)
      end
    end
  end
end
