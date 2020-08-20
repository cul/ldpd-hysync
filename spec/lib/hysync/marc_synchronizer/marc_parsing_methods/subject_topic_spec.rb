require 'rails_helper'

describe Hysync::MarcSynchronizer::MarcHyacinthRecord do
  let(:marc_record) do
    record = FactoryBot.build(:marc_record)
    record.append(MARC::DataField.new('650', '',  '0', ['a', 'Advertising agencies'], ['z', 'United States']))
    record.append(MARC::DataField.new('650', '',  '0', ['a', 'Photographers']))
    record
  end
  let(:marc_hyacinth_record) { Hysync::MarcSynchronizer::MarcHyacinthRecord.new(marc_record) }

  let(:expected) do
    [
      {"subject_topic_term" => {"value" => "Advertising agencies--United States", "authority" => "lcsh"}},
      {"subject_topic_term" => {"value" => "Photographers", "authority" => "lcsh"}}
    ]
  end
  it "extracts the correct subject topic" do
    actual = marc_hyacinth_record.digital_object_data['dynamic_field_data']['subject_topic']
    expect(actual).not_to be_empty
    expect(actual).to eql(expected)
  end

  context "when a replacable offensive term is present" do
    let(:marc_record_with_offensive_term) do
      marc_record.append(MARC::DataField.new('650', '',  '0', ['a', 'Aliens (Greek law)'], ['x', 'Officials and employees, Alien'], ['z', 'United States']))
      marc_record
    end
    let(:expected_with_replaced_offensive_term) do
      expected + [
        {"subject_topic_term" => {"value" => "Noncitizens (Greek law)--Officials and employees, Noncitizen--United States", "authority" => "lcsh"}}
      ]
    end
    let(:marc_hyacinth_record) { Hysync::MarcSynchronizer::MarcHyacinthRecord.new(marc_record_with_offensive_term) }

    it "extracts the correct subject topics and replaces the replacable offensive term with the expected value" do
      actual = marc_hyacinth_record.digital_object_data['dynamic_field_data']['subject_topic']
      expect(actual).to eql(expected_with_replaced_offensive_term)
    end
  end
end
