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
  context "with subject name titles" do
    let(:marc_fixture) { File.new("spec/fixtures/marc21/12998581.marc","rb") }
    it "sets a subject name title term" do
      actual = subject.digital_object_data['dynamic_field_data']

      expect(actual['subject_name'].detect { |s| s['subject_name_title_term'] }).to be_present
      expect(actual['subject_name'].detect { |s| !s['subject_name_title_term'] }).to be_blank
    end
  end
  context "with subject names" do
    let(:marc_fixture) { File.new("spec/fixtures/marc21/12584157.marc","rb") }
    it "sets a subject name term" do
      actual = subject.digital_object_data['dynamic_field_data']
      subject_name = actual['subject_name'].detect { |s| s['subject_name_term'] }
      expect(subject_name).to be_present
      subject_name_term = subject_name['subject_name_term']
      expect(subject_name_term['name_type']).to eql 'personal'
      expect(subject_name_term['value']).to eql 'Carnegie, Andrew, 1835-1919'
    end
  end
  context "with corporate name main entry" do
    let(:marc_fixture) { File.new("spec/fixtures/marc21/12998568.marc","rb") }
    it "sets a main entry name term" do
      actual = subject.digital_object_data['dynamic_field_data']
      first_primary = actual['name'].detect { |s| s['name_usage_primary'] }
      expect(first_primary).to be_present
      expect(first_primary['name_term']['value']).to eql('Carnegie Corporation of New York')
    end
  end
  context "with uniform title subjects" do
    it "sets a subject title term" do
      skip "until we have an example record with a 630 field"
    end
  end
end
