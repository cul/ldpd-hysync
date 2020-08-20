# frozen_string_literal: true

FactoryBot.define do
  factory :marc_record, class: MARC::Record do
    after(:build) do |record|
      record.leader = '01601ckdaa2200349 a 4500'
      record.append(MARC::ControlField.new('001', '1234567'))
      record.append(MARC::ControlField.new('005', '20190310095234.0'))
      record.append(MARC::ControlField.new('008', '171206d19542005nyuar   o     0   a0eng d'))
    end

    trait :collection do
      after(:build) do |record|
        # Replace default 001 with differnet value
        record.fields.delete(record.fields('001').first)
        record.append(MARC::ControlField.new('001', '3456789'))
      end
    end
  end
end
