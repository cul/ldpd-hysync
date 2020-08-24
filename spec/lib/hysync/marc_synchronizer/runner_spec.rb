require 'rails_helper'

describe Hysync::MarcSynchronizer::Runner do
  context ".extract_collection_record_title" do
    let(:collection_marc_record) do
      # TODO: Convert some of the code below into a factory (including the 001 and 005 fields, which are required)
      record = FactoryBot.build(:marc_record)
      record.append(MARC::DataField.new('245', '0',  '0', ['a', 'Carnegie Corporation project.'], ['n', 'Part 2 :']))
      record
    end
    it "extracts the expected title" do
      expect(described_class.extract_collection_record_title(collection_marc_record)).to eq('Carnegie Corporation project. Part 2')
    end
  end
end
