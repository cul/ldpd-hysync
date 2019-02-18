require 'rails_helper'

describe Hysync::MarcSynchronizer::MarcHyacinthRecord do
  let(:marc_fixture) { File.new("spec/fixtures/marc21/12584148.marc","rb") }
  # this json is just the expected strucutre of a parsed voyager record
  let(:json_fixture) { "spec/fixtures/json/12584148.import.json" }
  let(:json_record) { JSON.load(File.read(json_fixture)) }
	let(:marc_record) do
    MARC::Record.new_from_marc(marc_fixture.read)
  end
	subject { described_class.new(marc_record) }
  it "produces the expected dynamic field data" do
    actual = subject.digital_object_data['dynamic_field_data']
    deep_compact!(actual)
    expected = json_record['dynamic_field_data']
    expect(actual).to eql(expected)
  end
  context "with an archive.org identifier in a 920" do
    let(:marc_fixture) { File.new("spec/fixtures/marc21/11258902.marc","rb") }
    it "parses an archive.org idneitifer" do
      actual = subject.digital_object_data['dynamic_field_data']
      expect(actual["archive_org_identifier"]).not_to be_empty
      archive_org_identifier =  actual["archive_org_identifier"][0]["archive_org_identifier_value"]
      expect(archive_org_identifier).to eql("150thanniversary00tamm")
    end
  end
end