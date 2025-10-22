require 'rails_helper'

describe Hysync::MarcSynchronizer::MarcHyacinthRecord do
  let!(:cache) { Hysync::MarcSynchronizer::MarcParsingMethods::Collection::CACHE.dup }
  let(:marc_record) do
    record = FactoryBot.build(:marc_record)
    record.append(MARC::DataField.new('773', '0',  nil, ['w', w773]))
    record
  end
  let(:collection_record) do
    record = FactoryBot.build(:marc_record, :collection)
    record.append(MARC::DataField.new('035', nil,  nil, ['a', w773]))
    record
  end
  let(:folio_client) do
    double(Hysync::FolioApiClient)
  end
  before { Hysync::MarcSynchronizer::MarcParsingMethods::Collection::CACHE.clear }
  after { Hysync::MarcSynchronizer::MarcParsingMethods::Collection::CACHE.merge!(cache) }

  let(:marc_hyacinth_record) { Hysync::MarcSynchronizer::MarcHyacinthRecord.new(marc_record, [], {}, folio_client) }

  context "has a CLIO 773" do
    let(:w773) { '(NNC)2345678' }
    it "extracts the id into a collection term object" do
      expect(marc_hyacinth_record.collection_terms.first).to be_present
      expect(marc_hyacinth_record.collection_terms.first['collection_term']).to include('clio_id' => '2345678')
    end
  end

  # The code below is commented out because we're not doing this anymore.  Keeping it in case we decide to re-enable it later.
  # context "has a non-CLIO 773" do
  #   let(:w773) { '(CStRLIN)NYDA01-F181' }
  #   before do
  #     expect(folio_client).to receive(:search).with(1,20, w773).once.and_yield(marc_record, 0, 2).and_yield(collection_record, 1, 2)
  #   end
  #   it "caches the lookup value for non-CLIO 777$w values" do
  #     expect(marc_hyacinth_record.collection_terms.first).to be_present
  #     expect(marc_hyacinth_record.collection_terms.first['collection_term']).to include('clio_id' => '3456789')
  #     expect(Hysync::MarcSynchronizer::MarcParsingMethods::Collection::CACHE).to be_present
  #     marc_hyacinth_record.indirect_773w_term(marc_record, folio_client)
  #   end
  # end
end
