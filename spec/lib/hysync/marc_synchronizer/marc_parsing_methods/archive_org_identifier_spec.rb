require 'rails_helper'

describe Hysync::MarcSynchronizer::MarcHyacinthRecord do
  let(:marc_record) do
    # TODO: Convert some of the code below into a factory (including the 001 and 005 fields, which are required)
    record = MARC::Record.new
    record.append(MARC::ControlField.new('001', '1234567'))
    record.append(MARC::ControlField.new('005', '20190310095234.0'))
    record.append(MARC::ControlField.new('008', '171206d19542005nyuar   o     0   a0eng d'))
    record.append(MARC::DataField.new('920', '4',  '0', ['u', 'https://archive.org/details/abcdefg']))
    record.append(MARC::DataField.new('920', '4',  '0', ['u', 'https://www.archive.org/details/hijklmnop']))
    record
  end
  let(:marc_hyacinth_record) { Hysync::MarcSynchronizer::MarcHyacinthRecord.new(marc_record) }
  let(:expected) do
    [
      {"archive_org_identifier_value"=>"abcdefg"},
      {"archive_org_identifier_value"=>"hijklmnop"}
    ]
  end
  it "extracts the expected archive.org identifiers" do
    actual = marc_hyacinth_record.digital_object_data['dynamic_field_data']['archive_org_identifier']
    expect(actual).not_to be_empty
    expect(actual).to eql(expected)
  end
end
