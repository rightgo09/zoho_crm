# coding: utf-8
require 'spec_helper'

describe ZohoCrm do
  it 'should have a version number' do
    expect(ZohoCrm::VERSION).to_not be_nil
  end
end

ZohoCrm.const_set("BlackCoffee", Class.new { extend ZohoCrm::Util })

describe ZohoCrm::Util do
  let(:z) { ZohoCrm::BlackCoffee }

  describe "#build_url" do
    subject(:url) { z.build_url(:get_my_records) }
    it "should build url" do
      expect(url).to eq("https://crm.zoho.com/crm/private/json/BlackCoffees/getMyRecords")
    end
  end

  describe "#check_token" do
    context "when token is not set" do
      before { ZohoCrm.token = nil }
      it "should raise RuntimeError" do
        expect { z.check_token }.to raise_error(RuntimeError)
      end
    end

    context "when token is set" do
      let(:token) { "hogehogehoge" }
      before { ZohoCrm.token = token }
      it "should not raise RuntimeError" do
        expect { z.check_token }.not_to raise_error
      end
    end
  end

  describe "#build_query" do
    let(:token) { "hogehogehoge" }
    let(:predefined_query) { {"scope" => "crmapi", "authtoken" => token} }
    let(:expected_query) { predefined_query.merge(built_query) }
    before { ZohoCrm.token = token }

    shared_examples_for "building query" do
      it "should build query" do
        expect(query).to eq(expected_query)
      end
    end

    context "when query includes snake_case" do
      it_should_behave_like "building query" do
        subject(:query) { z.build_query({new_format: 1}) }
        let(:built_query) { {"newFormat" => 1} }
      end
    end

    context "when query includes select_columns" do
      context 'that is "All"' do
        it_should_behave_like "building query" do
          subject(:query) { z.build_query({select_columns: "All"}) }
          let(:built_query) { {"selectColumns" => "All"} }
        end
      end

      context 'that is ["店舗名"]' do
        it_should_behave_like "building query" do
          subject(:query) { z.build_query({select_columns: ["店舗名"]}) }
          let(:built_query) { {"selectColumns" => "BlackCoffees(店舗名)"} }
        end
      end

      context 'that is ["店舗名","産地"]' do
        it_should_behave_like "building query" do
          subject(:query) { z.build_query({select_columns: ["店舗名", "産地"]}) }
          let(:built_query) { {"selectColumns" => "BlackCoffees(店舗名,産地)"} }
        end
      end
    end

    context "when query includes search_condition" do
      context "that is partial match" do
        it_should_behave_like "building query" do
          subject(:query) { z.build_query({search_condition: {"店舗名" => {"contains" => "スター"}}}) }
          let(:built_query) { {"searchCondition" => "(店舗名|contains|*スター*)"} }
        end
      end

      context "that is prefix match" do
        it_should_behave_like "building query" do
          subject(:query) { z.build_query({search_condition: {"店舗名" => {"starts with" => "スター"}}}) }
          let(:built_query) { {"searchCondition" => "(店舗名|starts with|スター*)"} }
        end
      end

      context "that is suffix match" do
        it_should_behave_like "building query" do
          subject(:query) { z.build_query({search_condition: {"店舗名" => {"ends with" => "バックス"}}}) }
          let(:built_query) { {"searchCondition" => "(店舗名|ends with|*バックス)"} }
        end
      end

      context "that is equal match" do
        it_should_behave_like "building query" do
          subject(:query) { z.build_query({search_condition: {"店舗名" => {"=" => "スターバックス"}}}) }
          let(:built_query) { {"searchCondition" => "(店舗名|=|スターバックス)"} }
        end
      end
    end

    context "when query is xml_data" do
      it_should_behave_like "building query" do
        subject(:query) { z.build_query({xml_data: {"商品名" => "ブラック&コーヒー"}}) }
        let(:built_query) { {"xmlData" => '<BlackCoffees><row no="1"><FL val="商品名">ブラック&amp;コーヒー</FL></row></BlackCoffees>'} }
      end
    end
  end

  shared_examples_for "the case of no data" do
    before { $stderr.should_receive(:puts).with(message) }

    it "should return empty array" do
      expect(results).to eq([])
      expect(z.message).to eq(message)
    end
  end

  describe "#fetch" do
    let(:url) { "http://www.example.com" }
    let(:query) { {"a" => 1} }
    let(:token) { "hogehogehoge" }
    let(:expected_query) { query.merge("authtoken" => token, "scope" => "crmapi") }
    let(:response) { double(:response, code: code, body: body) }
    let(:code) { 200 }

    before do
      ZohoCrm.token = token
      HTTParty.should_receive(:get).with(url, {query: expected_query}).and_return(response)
    end

    subject(:results) { z.fetch(url, query) }

    context "when response code is not 200" do
      let(:code) { 500 }
      let(:body) { "error" }

      it "should return empty array" do
        $stderr.should_receive(:puts).with("Zoho API HTTP status code is [#{code}], body is [#{body}].")
        expect(results).to eq([])
      end
    end

    context "when response includes 1 row and 1 content" do
      let(:body) { '{"response":{"result":{"BlackCoffees":{"row":{"no":"1","FL":{"content":"スターバックス","val":"店舗名"}}}},"uri":"/"}}' }

      it "should return parsed hash in array" do
        expect(results).to eq([{"店舗名" => "スターバックス"}])
      end
    end

    context "when response includes 1 row and 2 contents" do
      let(:body) { '{"response":{"result":{"BlackCoffees":{"row":{"no":"1","FL":[{"content":"スターバックス","val":"店舗名"},{"content":"Starbucks","val":"Store Name"}]}}},"uri":"/"}}' }

      it "should return parsed hash in array" do
        expect(results).to eq([{"店舗名" => "スターバックス", "Store Name" => "Starbucks"}])
      end
    end

    context "when response includes 2 row and 1 content" do
      let(:body) { '{"response":{"result":{"BlackCoffees":{"row":[{"no":"1","FL":{"content":"スターバックス","val":"店舗名"}},{"no":"2","FL":{"content":"ドトール","val":"店舗名"}}]}},"uri":"/"}}' }

      it "should return parsed hash in array" do
        expect(results).to eq([{"店舗名" => "スターバックス"}, {"店舗名" => "ドトール"}])
      end
    end

    context "when content is null" do
      let(:body) { '{"response":{"result":{"BlackCoffees":{"row":{"no":"1","FL":{"content":"null","val":"店舗名"}}}},"uri":"/"}}' }

      it "should return nil" do
        expect(results).to eq([{"店舗名" => nil}])
      end
    end

    context "when response includes error" do
      it_should_behave_like "the case of no data" do
        let(:message) { "Invalid Ticket Id" }
        let(:body) { %Q!{"response":{"error":{"message":"#{message}","code":"4834"},"uri":"/"}}! }
      end
    end

    context "when response includes no data" do
      it_should_behave_like "the case of no data" do
        let(:message) { "There is no data to show" }
        let(:body) { %Q!{"response":{"nodata":{"message":"#{message}","code":"4422"},"uri":"/"}}! }
      end
    end
  end

  describe "#insert" do
    let(:url) { "http://www.example.com" }
    let(:query) { {"a" => 1} }
    let(:token) { "hogehogehoge" }
    let(:expected_query) { query.merge("authtoken" => token, "scope" => "crmapi") }
    let(:response) { double(:response, code: code, body: body) }
    let(:code) { 200 }

    before do
      ZohoCrm.token = token
      HTTParty.should_receive(:post).with(url, { query: expected_query }).and_return(response)
    end

    subject(:results) { z.insert(url, query) }

    context "when data is successfully inserted" do
      let(:message) { "Record(s) added successfully" }
      let(:body) { %Q!{"response":{"result":{"recorddetail":{"FL":[{"val":"Id","content":"2434346000000149011"},{"val":"Created Time","content":"2017-04-03 10:02:44"}]}},"uri":"/"}}! }

      it "should return empty array" do
        expect(results).to eq([{"Id"=>"2434346000000149011", "Created Time"=>"2017-04-03 10:02:44"}])
      end
    end
  end

  describe "#update" do
    let(:url) { "http://www.example.com" }
    let(:query) { {"a" => 1} }
    let(:token) { "hogehogehoge" }
    let(:expected_query) { query.merge("authtoken" => token, "scope" => "crmapi") }
    let(:response) { double(:response, code: code, body: body) }
    let(:code) { 200 }

    before do
      ZohoCrm.token = token
      HTTParty.should_receive(:post).with(url, {query: expected_query}).and_return(response)
    end

    subject(:results) { z.update(url, query) }

    context "when response code is not 200" do
      let(:code) { 500 }
      let(:body) { "error" }

      it "should return empty array" do
        $stderr.should_receive(:puts).with("Zoho API HTTP status code is [#{code}], body is [#{body}].")
        expect(results).to eq([])
      end
    end

    context "when data is successfully updated" do
      let(:message) { "Record(s) updated successfully" }
      let(:body) { %Q!{"response":{"result":{"message":"#{message}","recorddetail":{"FL":[{"content":"111111111111111111","val":"Id"},{"content":"2014-03-03 12:00:00","val":"Created Time"},{"content":"2014-03-03 13:00:00","val":"Modified Time"},{"content":"r9","val":"Created By"},{"content":"r9","val":"Modified By"}]}},"uri":"/"}}! }

      it "should return parsed hash in array" do
        expect(results).to eq([{"Id" => "111111111111111111", "Created Time" => "2014-03-03 12:00:00", "Modified Time" => "2014-03-03 13:00:00", "Created By" => "r9", "Modified By" => "r9"}])
      end
    end

    context "when response includes error" do
      it_should_behave_like "the case of no data" do
        let(:message) { "Invalid Ticket Id" }
        let(:body) { %Q!{"response":{"error":{"message":"#{message}","code":"4834"},"uri":"/"}}! }
      end
    end

  end

  describe "#delete" do
    let(:url) { "http://www.example.com" }
    let(:query) { {"a" => 1} }
    let(:token) { "hogehogehoge" }
    let(:expected_query) { query.merge("authtoken" => token, "scope" => "crmapi") }
    let(:response) { double(:response, code: code, body: body) }
    let(:code) { 200 }

    before do
      ZohoCrm.token = token
      HTTParty.should_receive(:get).with(url, {query: expected_query}).and_return(response)
    end

    subject(:results) { z.delete(url, query) }

    context "when data is successfully deleted" do
      let(:message) { "Record Id(s) : 111111111111111111,Record(s) deleted successfully" }
      let(:body) { %Q!{"response":{"result":{"message":"#{message}","code":"5000"},"uri":"/"}}! }

      it "should return empty array" do
        expect(results).to eq([])
      end
    end
  end

end
