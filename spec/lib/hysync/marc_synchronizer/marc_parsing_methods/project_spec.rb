require 'rails_helper'

describe Hysync::MarcSynchronizer::MarcHyacinthRecord do
  let(:marc_record) do
    record = FactoryBot.build(:marc_record)
    record.append(MARC::DataField.new('965', ' ',  ' ', ['a', '965carnegiedpf']))
    record.append(MARC::DataField.new('965', ' ',  ' ', ['a', '965TBM']))
    record.append(MARC::DataField.new('965', ' ',  ' ', ['a', '965tibetan']))
    record
  end
  let(:marc_hyacinth_record) { Hysync::MarcSynchronizer::MarcHyacinthRecord.new(marc_record) }
  let(:expected) do
    [
      {"other_project_term"=>{"uri" => "info:hyacinth.library.columbia.edu/projects/TBM"}},
      {"other_project_term"=>{"uri" => "info:hyacinth.library.columbia.edu/projects/tibetan"}},
    ]
  end
  it "sets the project from the first value" do
    expect(marc_hyacinth_record.errors).to be_empty
    actual = marc_hyacinth_record.digital_object_data['project']['string_key']
    expect(actual).to eql('carnegie_dpf')
  end
  it "extracts the expected archive.org identifiers" do
    actual = marc_hyacinth_record.digital_object_data['dynamic_field_data']['other_project']
    expect(actual).not_to be_empty
    expect(actual).to eql(expected)
  end
end
