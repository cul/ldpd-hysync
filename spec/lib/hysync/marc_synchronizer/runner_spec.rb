require 'rails_helper'

describe Hysync::MarcSynchronizer::Runner do
  context ".extract_collection_record_title" do
    let(:collection_marc_record) do
      # TODO: Convert some of the code below into a factory (including the 001 and 005 fields, which are required)
      record = MARC::Record.new
      record.append(MARC::ControlField.new('001', '1234567'))
      record.append(MARC::ControlField.new('005', '20190310095234.0'))
      record.append(MARC::ControlField.new('008', '171206d19542005nyuar   o     0   a0eng d'))
      record.append(MARC::DataField.new('245', '0',  '0', ['a', 'Carnegie Corporation project.'], ['n', 'Part 2 :']))
      record
    end
    it "extracts the expected title" do
      expect(described_class.extract_collection_record_title(collection_marc_record)).to eq('Carnegie Corporation project. Part 2')
    end
  end
end
