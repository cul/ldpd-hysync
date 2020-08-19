require 'rails_helper'

describe MarcSelector do
  let(:marc_record) do
    # TODO: Convert some of the code below into a factory (including the 001 and 005 fields, which are required)
    record = MARC::Record.new
    record.append(MARC::ControlField.new('001', '1234567'))
    record.append(MARC::ControlField.new('005', '20190310095234.0'))
    record.append(MARC::ControlField.new('008', '171206d19542005nyuar   o     0   a0eng d'))
    record
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
    it "concatenates as expected" do
      expect(described_class.concat_subfield_values(field, subfield_keys)).to eq('Part A. Part C. ')
    end

    it "cleans trailing punctuation when clean param is given" do
      expect(described_class.concat_subfield_values(field, subfield_keys, true)).to eq('Part A. Part C')
    end
  end
end
