require 'rails_helper'

describe Hysync::MarcSynchronizer::MarcHyacinthRecord do
  let(:marc_record) do
    record = FactoryBot.build(:marc_record)
    record.append(MARC::DataField.new('920', '4',  '0', ['u', 'https://archive.org/details/abcdefg']))
    record.append(MARC::DataField.new('920', '4',  '0', ['u', 'https://www.archive.org/details/hijklmnop']))
    record.append(MARC::DataField.new('920', '4',  '0', ['u', 'http://www.archive.org/details/qrstuvwxyz']))
    record
  end
  let(:marc_hyacinth_record) { Hysync::MarcSynchronizer::MarcHyacinthRecord.new(marc_record) }
  let(:expected) do
    [
      {"archive_org_identifier_value"=>"abcdefg"},
      {"archive_org_identifier_value"=>"hijklmnop"},
      {"archive_org_identifier_value"=>"qrstuvwxyz"}
    ]
  end
  it "extracts the expected archive.org identifiers" do
    actual = marc_hyacinth_record.digital_object_data['dynamic_field_data']['archive_org_identifier']
    expect(actual).not_to be_empty
    expect(actual).to eql(expected)
  end
end
