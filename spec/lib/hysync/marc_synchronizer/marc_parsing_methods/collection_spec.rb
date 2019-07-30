require 'rails_helper'

describe Hysync::MarcSynchronizer::MarcHyacinthRecord do
  let!(:cache) { Hysync::MarcSynchronizer::MarcParsingMethods::Collection::CACHE.dup }
  let(:marc_record) do
    # TODO: Convert some of the code below into a factory (including the 001 and 005 fields, which are required)
    record = MARC::Record.new
    record.append(MARC::ControlField.new('001', '1234567'))
    record.append(MARC::ControlField.new('005', '20190310095234.0'))
    record.append(MARC::ControlField.new('008', '171206d19542005nyuar   o     0   a0eng d'))
    record.append(MARC::DataField.new('773', '0',  nil, ['w', w773]))
    record
  end
  let(:collection_record) do
    record = MARC::Record.new
    record.append(MARC::ControlField.new('001', '3456789'))
    record.append(MARC::ControlField.new('005', '20190310095234.0'))
    record.append(MARC::ControlField.new('008', '171206d19542005nyuar   o     0   a0eng d'))
    record.append(MARC::DataField.new('035', nil,  nil, ['a', w773]))
    record
  end
  let(:voyager_client) { double(Voyager::Client) }
  before { Hysync::MarcSynchronizer::MarcParsingMethods::Collection::CACHE.clear }
  after { Hysync::MarcSynchronizer::MarcParsingMethods::Collection::CACHE.merge!(cache) }

  let(:marc_hyacinth_record) { Hysync::MarcSynchronizer::MarcHyacinthRecord.new(marc_record, [], {}, voyager_client) }

  let(:expected) do
    [
      {"archive_org_identifier_value"=>"abcdefg"},
      {"archive_org_identifier_value"=>"hijklmnop"},
      {"archive_org_identifier_value"=>"qrstuvwxyz"}
    ]
  end
  context "has a CLIO 773" do
    let(:w773) { '(NNC)2345678' }
    it "does not look up a value to cache" do
      expect(marc_hyacinth_record.collection_terms.first).to be_present
      expect(marc_hyacinth_record.collection_terms.first['collection_term']).to include('clio_id' => '2345678')
      expect(Hysync::MarcSynchronizer::MarcParsingMethods::Collection::CACHE).to be_empty
    end
  end
  context "has a non-CLIO 773" do
    let(:w773) { '(CStRLIN)NYDA01-F181' }
    before do
      expect(voyager_client).to receive(:search).with(1,20, w773).once.and_yield(marc_record, 0, 2).and_yield(collection_record, 1, 2)
    end
    it "caches the lookup value for non-CLIO 777$w values" do
      expect(marc_hyacinth_record.collection_terms.first).to be_present
      expect(marc_hyacinth_record.collection_terms.first['collection_term']).to include('clio_id' => '3456789')
      expect(Hysync::MarcSynchronizer::MarcParsingMethods::Collection::CACHE).to be_present
      marc_hyacinth_record.indirect_773w_term(marc_record, voyager_client)
    end
  end
end
