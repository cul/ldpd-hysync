require 'rails_helper'

describe MarcSelector do
  let(:marc_record) do
    FactoryBot.build(:marc_record)
  end

  context ".concat_subfield_values" do
    let(:field) do
      marc_record.append(MARC::DataField.new('245', '0',  '0',
        ['a', 'Part A.'],
        ['c', 'Part C. '],
      ))
      described_class.first(marc_record, '245')
    end
    let(:subfield_keys) do
      ['a', 'b', 'c']
    end
    it "concatenates as expected, cleaning trailing punctuation by default" do
      expect(described_class.concat_subfield_values(field, subfield_keys)).to eq('Part A. Part C')
    end

    it "does not clean trailing punctuation when clean=false param is given" do
      expect(described_class.concat_subfield_values(field, subfield_keys, false)).to eq('Part A. Part C. ')
    end
  end
end
