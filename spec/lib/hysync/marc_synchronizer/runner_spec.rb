require 'rails_helper'

describe Hysync::MarcSynchronizer::Runner do
  describe ".extract_collection_record_title" do
    let(:collection_marc_record) do
      # TODO: Convert some of the code below into a factory (including the 001 and 005 fields, which are required)
      record = FactoryBot.build(:marc_record)
      record.append(MARC::DataField.new('245', '0',  '0', ['a', 'Carnegie Corporation project.'], ['n', 'Part 2 :']))
      record
    end
    it "extracts the expected title" do
      expect(described_class.extract_collection_record_title(collection_marc_record)).to eq('Carnegie Corporation project. Part 2')
    end
  end
  describe '#update_indicated?' do
    let(:runner) { described_class.allocate }
    let(:same_005) { '20150713190008.1' }
    let(:different_005) { '20150713190008.0' }
    let(:force_update) { false }
    let(:marc_005) { early_005 }
    let(:marc_record) do
      record = FactoryBot.build(:marc_record)
      record.fields.delete(record.fields('005').first)
      record.append(MARC::ControlField.new('005', same_005))
      record
    end
    let(:hyacinth_record) {
      record = described_class.default_digital_object_data
      record['dynamic_field_data']['marc_005_last_modified'] = [{'marc_005_last_modified_value' => same_005}]
      record
    }
    subject { runner.update_indicated?(marc_record, hyacinth_record, force_update) }
    context 'force_update flag is set' do
      let(:force_update) { true }
      it { is_expected.to be true }
    end
    context 'no hyacinth 005 recorded' do
      let(:hyacinth_record) {
        described_class.default_digital_object_data
      }
      it { is_expected.to be true }
    end
    context 'no marc 005 is recorded' do
      subject { nil }
      pending 'raises an error' do
        expect { runner.update_indicated?(marc_record, hyacinth_record, force_update) }.to raise_error
      end
    end
    context 'hyacinth and marc 005 differ' do
      let(:hyacinth_record) {
        record = described_class.default_digital_object_data
        record['dynamic_field_data']['marc_005_last_modified'] = [{'marc_005_last_modified_value' => different_005}]
        record
      }
      it { is_expected.to be true }
    end
    context 'hyacinth and marc 005 do not differ' do
      it { is_expected.to be false }
    end
  end
end
