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
    pending("fixture cleanup, hash compacting, and expectation docs")
    actual = subject.digital_object_data['dynamic_field_data']
    deep_compact!(actual)
    expected = json_record['dynamic_field_data']
    expect(actual).to eql(expected)
  end
end