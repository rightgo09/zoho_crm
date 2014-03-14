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

end
