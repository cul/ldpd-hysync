require 'rails_helper'

describe Hysync::MarcSynchronizer::MarcHyacinthRecord do
  let(:marc_record) do
    record = FactoryBot.build(:marc_record)
    record.append(MARC::DataField.new('024', '8',  '', ['a', 'abc123']))
    record.append(MARC::DataField.new('024', '8',  '', ['a', 'abc456']))
    record
  end
  let(:marc_hyacinth_record) { Hysync::MarcSynchronizer::MarcHyacinthRecord.new(marc_record) }
  let(:expected) do
    [
      {"local_identifier_value"=>"abc123"},
      {"local_identifier_value"=>"abc456"}
    ]
  end
  it "extracts the expected local identifiers" do
    actual = marc_hyacinth_record.digital_object_data['dynamic_field_data']['local_identifier']
    expect(actual).not_to be_empty
    expect(actual).to eql(expected)
  end
end
