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
  let(:expected) { 'http://id.loc.gov/vocabulary/graphicMaterials/tgm007779' }
  it "extracts the expected form" do
    actual = marc_hyacinth_record.digital_object_data['dynamic_field_data']['form'].map { |x| x['form_term']['uri'] }
    expect(actual).to eql([expected])
  end
end
