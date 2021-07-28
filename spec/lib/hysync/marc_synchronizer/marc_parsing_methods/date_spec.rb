require 'rails_helper'

describe Hysync::MarcSynchronizer::MarcHyacinthRecord do
  let(:marc_record) do
    # TODO: Convert some of the code below into a factory (including the 001 and 005 fields, which are required)
    record = MARC::Record.new
    record.leader = '01601ckdaa2200349 a 4500'
    record.append(MARC::ControlField.new('001', '1234567'))
    record.append(MARC::ControlField.new('005', '20190310095234.0'))
    record
  end
  let(:marc_hyacinth_record) { Hysync::MarcSynchronizer::MarcHyacinthRecord.new(marc_record) }

  context "#add_date_created" do
    let(:date1) { '1900' }
    let(:date2) { '1902' }
    let(:date_type) { 'q' }
    let(:is_keydate) { true }

    it "adds the expected date_created field" do
      marc_hyacinth_record.add_date_created(date1, date2, date_type, is_keydate)
      expect(marc_hyacinth_record.digital_object_data['dynamic_field_data']['date_created']).to eq([
        {
          'date_created_start_value' => '1900',
          'date_created_end_value' => '1902',
          'date_created_key_date' => true,
          'date_created_type' => 'questionable'
        }
      ])
    end

    it "does not add a date if date1 and date2 args are both nil" do
      marc_hyacinth_record.add_date_created(nil, nil, date_type, is_keydate)
      expect(marc_hyacinth_record.digital_object_data['dynamic_field_data']['date_created']).to be_blank
    end
  end

  context "#add_date_issued" do
    let(:date1) { '1900' }
    let(:date2) { '1902' }
    let(:date_type) { 'q' }
    let(:is_keydate) { true }

    it "adds the expected date_issued field" do
      marc_hyacinth_record.add_date_issued(date1, date2, date_type, is_keydate)
      expect(marc_hyacinth_record.digital_object_data['dynamic_field_data']['date_issued']).to eq([
        {
          'date_issued_start_value' => '1900',
          'date_issued_end_value' => '1902',
          'date_issued_key_date' => true,
          'date_issued_type' => 'questionable'
        }
      ])
    end

    it "does not add a date if date1 and date2 args are both nil" do
      marc_hyacinth_record.add_date_issued(nil, nil, date_type, is_keydate)
      expect(marc_hyacinth_record.digital_object_data['dynamic_field_data']['date_issued']).to be_blank
    end
  end

  context '#normalize_date' do
    {
      '19xx' => '19XX',
      '19uu' => '19XX',
      '19??' => '19XX',
      '????' => '',
      nil => nil
    }.each do |original, expected|
      it "converts '#{original}' to '#{expected}'" do
        expect(marc_hyacinth_record.normalize_date(original)).to eq(expected)
      end
    end
  end
end
