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
    let(:hyacinth_record) do
      record = described_class.default_digital_object_data
      record['dynamic_field_data']['marc_005_last_modified'] = [{'marc_005_last_modified_value' => same_005}]
      record
    end
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
      let(:hyacinth_record) do
        record = described_class.default_digital_object_data
        record['dynamic_field_data']['marc_005_last_modified'] = [{'marc_005_last_modified_value' => different_005}]
        record
      end
      it { is_expected.to be true }
    end
    context 'hyacinth and marc 005 do not differ' do
      it { is_expected.to be false }
    end
  end
  describe '#reconcile_identifiers!' do
    let(:runner) { described_class.allocate }
    let(:default_data) { described_class.default_digital_object_data }
    let(:marc_record) do
      FactoryBot.build(:marc_record)
    end
    let(:marc_ids) { [] }
    let(:marc_hyacinth_record) do
      Hysync::MarcSynchronizer::MarcHyacinthRecord.new(marc_record, [], default_data.merge('identifiers' => marc_ids.dup))
    end
    let(:hyacinth_ids) { [] }
    let(:existing_hyacinth_record) do
      record = described_class.default_digital_object_data.merge('identifiers' => hyacinth_ids.dup)
      record
    end
    before do
      runner.reconcile_identifiers!(marc_hyacinth_record, existing_hyacinth_record)
    end
    context 'marc is superset of hyacinth' do
      let(:marc_ids) { ['abc123', 'abc456'] }
      let(:hyacinth_ids) { ['abc456'] }
      let(:expected) { marc_ids }
      it 'preserves marc identifiers in order' do
        expect(marc_hyacinth_record.digital_object_data['identifiers']).to eql(expected)
      end
    end
    context 'hyacinth is superset of marc' do
      let(:marc_ids) { ['abc456'] }
      let(:hyacinth_ids) { ['abc123', 'abc456'] }
      let(:expected) { ['abc456', 'abc123'] }
      it 'reorders the union to match marc order first' do
        expect(marc_hyacinth_record.digital_object_data['identifiers']).to eql(expected)
      end
    end
    context 'marc and hyacinth identifier sets are equal' do
      let(:marc_ids) { ['abc123', 'abc456'] }
      let(:hyacinth_ids) { marc_ids.reverse }
      let(:expected) { marc_ids }
      it 'reorders the union to match marc order' do
        expect(marc_hyacinth_record.digital_object_data['identifiers']).to eql(expected)
      end
    end
    context 'marc and hyacinth identifier sets are disjoint' do
      let(:marc_ids) { ['abc123', 'abc456'] }
      let(:hyacinth_ids) { ['abc789', '123abc'] }
      let(:expected) { marc_ids + hyacinth_ids }
      it 'assigns the union of values, marc first' do
        expect(marc_hyacinth_record.digital_object_data['identifiers']).to eql(expected)
      end
    end
  end
  describe '#reconcile_projects!' do
    let(:runner) { described_class.allocate }
    let(:hyacinth_project) { 'hyacinth_only' }
    let(:default_data) { described_class.default_digital_object_data }
    let(:marc_record) do
      record = FactoryBot.build(:marc_record)
      marc_ids.each do |key|
        record.append(MARC::DataField.new('965', ' ',  ' ', ['a', "965#{key}"]))
      end
      record
    end
    let(:marc_ids) { [] }
    let(:marc_projects) { marc_ids.map {|string_key| Hysync::MarcSynchronizer::MarcParsingMethods::Project.hyacinth_2_project_term(string_key) } }
    let(:marc_hyacinth_record) do
      Hysync::MarcSynchronizer::MarcHyacinthRecord.new(marc_record, [], default_data.merge('identifiers' => marc_ids.dup))
    end
    let(:hyacinth_ids) { [] }
    let(:hyc_projects) { hyacinth_ids.map {|string_key| Hysync::MarcSynchronizer::MarcParsingMethods::Project.hyacinth_2_project_term(string_key) } }
    let(:existing_hyacinth_record) do
      record = described_class.default_digital_object_data.merge('identifiers' => hyacinth_ids.dup)
      record['project'] = {'string_key' => hyacinth_project}
      record['dynamic_field_data']['other_project'] = hyc_projects.dup
      record
    end
    before do
      runner.reconcile_projects!(marc_hyacinth_record, existing_hyacinth_record)
    end
    context 'marc is superset of hyacinth' do
      let(:marc_ids) { ['tibetan', 'TBM'] }
      let(:hyacinth_ids) { ['TBM'] }
      let(:expected) { hyacinth_ids | marc_ids }
      it 'assigns union of values with hyacinth order preserved' do
        actual = marc_hyacinth_record.dynamic_field_data.fetch('other_project', []).map {|v| v.dig('other_project_term', 'uri')}
        actual.map! { |u| u.split('/')[-1] }
        expect(actual).to eql(expected)
        existing_project = existing_hyacinth_record.dig('project', 'string_key')
        proposed_project = marc_hyacinth_record.digital_object_data.dig('project','string_key')
        expect(proposed_project).to eql(existing_project)
      end
    end
    context 'hyacinth is superset of marc' do
      let(:marc_ids) { ['TBM'] }
      let(:hyacinth_ids) { ['tibetan', 'TBM'] }
      let(:expected) { hyacinth_ids }
      it 'assigns union of values with hyacinth order preserved' do
        actual = marc_hyacinth_record.dynamic_field_data.fetch('other_project', []).map {|v| v.dig('other_project_term', 'uri')}
        actual.map! { |u| u.split('/')[-1] }
        expect(actual).to eql(expected)
        existing_project = existing_hyacinth_record.dig('project', 'string_key')
        proposed_project = marc_hyacinth_record.digital_object_data.dig('project','string_key')
        expect(proposed_project).to eql(existing_project)
      end
    end
    context 'marc and hyacinth identifier sets are equal' do
      let(:marc_ids) { ['tibetan', 'TBM'] }
      let(:hyacinth_ids) { marc_ids.reverse }
      let(:expected) { hyacinth_ids }
      it 'assigns union of values with hyacinth order preserved' do
        actual = marc_hyacinth_record.dynamic_field_data.fetch('other_project', []).map {|v| v.dig('other_project_term', 'uri')}
        actual.map! { |u| u.split('/')[-1] }
        expect(actual).to eql(expected)
        existing_project = existing_hyacinth_record.dig('project', 'string_key')
        proposed_project = marc_hyacinth_record.digital_object_data.dig('project','string_key')
        expect(proposed_project).to eql(existing_project)
      end
    end
    context 'marc and hyacinth identifier sets are disjoint' do
      let(:marc_ids) { ['tibetan', 'TBM'] }
      let(:hyacinth_ids) { ['carnegie_dpf'] }
      let(:expected) { hyacinth_ids + marc_ids }
      it 'assigns union of values with hyacinth order preserved' do
        actual = marc_hyacinth_record.dynamic_field_data.fetch('other_project', []).map {|v| v.dig('other_project_term', 'uri')}
        actual.map! { |u| u.split('/')[-1] }
        expect(actual).to eql(expected)
        existing_project = existing_hyacinth_record.dig('project', 'string_key')
        proposed_project = marc_hyacinth_record.digital_object_data.dig('project','string_key')
        expect(proposed_project).to eql(existing_project)
      end
    end
  end
end
