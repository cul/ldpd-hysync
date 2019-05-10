require 'rails_helper'

describe Hysync::MarcSynchronizer::MarcHyacinthRecord do
  let(:marc_fixture) { File.new("spec/fixtures/marc21/12584148.marc","rb") }
  # this json is just the expected strucutre of a parsed voyager record
  let(:json_fixture) { "spec/fixtures/json/12584148.import.json" }
  let(:json_record) { JSON.load(File.read(json_fixture)) }
	let(:marc_record) do
    MARC::Record.new_from_marc(marc_fixture.read)
  end
  before(:all) do
    @project_mappings = HYSYNC['project_mappings']
    @target_mappings = HYSYNC['publish_target_mappings']
    HYSYNC['project_mappings'] = { '965carnegiedpf' => 'carnegie_dpf', '965Durst' => 'durst' } 
    HYSYNC['publish_target_mappings'] = { '965carnegiedpf' => 'carnegie_staging', '965Durst' => 'dlc_catalog_staging' } 
  end
  after(:all) do
    HYSYNC['project_mappings'] = @project_mappings
    HYSYNC['publish_target_mappings'] = @target_mappings
  end

	subject { described_class.new(marc_record) }
  it "produces the expected dynamic field data" do
    actual = subject.digital_object_data['dynamic_field_data']
    deep_compact!(actual)
    expected = json_record['dynamic_field_data']
    expect(actual).to eql(expected)
  end
  it "produces the expected project" do
    actual = subject.digital_object_data['project']
    deep_compact!(actual)
    expected = json_record['project']
    expect(actual).to eql(expected)
  end
  it "produces the expected publish_targets" do
    actual = subject.digital_object_data['publish_targets']
    deep_compact!(actual)
    expected = json_record['publish_targets']
    expect(actual).to eql(expected)
  end
  context "with an archive.org identifier in a 920" do
    let(:marc_fixture) { File.new("spec/fixtures/marc21/11258902.marc","rb") }
    it "parses an archive.org identifier" do
      actual = subject.digital_object_data['dynamic_field_data']
      expect(actual["archive_org_identifier"]).not_to be_empty
      archive_org_identifier =  actual["archive_org_identifier"][0]["archive_org_identifier_value"]
      expect(archive_org_identifier).to eql("150thanniversary00tamm")
    end
  end
  context "with data in 506$a" do
    it "does not set an access restriction, but a deprecated note" do
      actual = subject.digital_object_data['dynamic_field_data']
      expect(actual["restriction_on_access"]).to be_blank
      expect(actual["restriction_on_access_deprecated"]).not_to be_empty
      deprecated_note = actual["restriction_on_access_deprecated"][0]["restriction_on_access_deprecated_value"]
      expect(deprecated_note).to eql("Digital version available with no restrictions")
    end
  end
end
