require 'rails_helper'

describe Hysync::MarcSynchronizer::MarcHyacinthRecord do
  let(:marc_record) do
    record = FactoryBot.build(:marc_record)
    record.append(MARC::DataField.new('540', '',  '', ['a', 'Note 1']))
    record.append(MARC::DataField.new('540', '',  '', ['a', 'Note 2']))
    record
  end
  let(:marc_hyacinth_record) { Hysync::MarcSynchronizer::MarcHyacinthRecord.new(marc_record) }
  let(:expected) do
    [
      {"note_value"=>"Note 1"},
      {"note_value"=>"Note 2"}
    ]
  end

  context "when mapping_ruleset equals 'video'" do
    before do
      marc_record.append(MARC::DataField.new('965', '',  '', ['a', '965hyacinth'], ['b', 'video']))
    end
    it "extracts the expected rights notes" do
      actual = marc_hyacinth_record.digital_object_data['dynamic_field_data']['note']
      expect(actual).not_to be_empty
      expect(actual).to eq(expected)
    end
  end

  context "when mapping_ruleset does not equal 'video'" do
    it "does not extract rights notes" do
      actual = marc_hyacinth_record.digital_object_data['dynamic_field_data']['note']
      expect(actual).to be_empty
    end
  end
end
