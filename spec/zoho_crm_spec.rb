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
    before { ZohoCrm.token = token }

    context "when query is snake_case" do
      subject(:query) { z.build_query({new_format: 1}) }
      it "should convert camel case" do
        expect(query).to eq(predefined_query.merge({"newFormat" => 1}))
      end
    end

    context "when query is select_columns" do
      context 'that is "All"' do
        subject(:query) { z.build_query({select_columns: "All"}) }
        it "should convert selectColumns => string" do
          expect(query).to eq(predefined_query.merge({"selectColumns" => "All"}))
        end
      end

      context 'that is ["店舗名"]' do
        subject(:query) { z.build_query({select_columns: ["店舗名"]}) }
        it "should convert selectColumns => Module(column)" do
          expect(query).to eq(predefined_query.merge({"selectColumns" => "BlackCoffees(店舗名)"}))
        end
      end

      context 'that is ["店舗名","産地"]' do
        subject(:query) { z.build_query({select_columns: ["店舗名", "産地"]}) }
        it "should convert selectColumns => Module(column,column)" do
          expect(query).to eq(predefined_query.merge({"selectColumns" => "BlackCoffees(店舗名,産地)"}))
        end
      end
    end

    context "when query is search_condition" do
      context "that is partial match" do
        subject(:query) { z.build_query({search_condition: {"店舗名" => {"contains" => "スター"}}}) }
        it "should convert searchCondition => (Field|contains|*word*)" do
          expect(query).to eq(predefined_query.merge({"searchCondition" => "(店舗名|contains|*スター*)"}))
        end
      end

      context "that is prefix match" do
        subject(:query) { z.build_query({search_condition: {"店舗名" => {"starts with" => "スター"}}}) }
        it "should convert searchCondition => (Field|starts with|word*)" do
          expect(query).to eq(predefined_query.merge({"searchCondition" => "(店舗名|starts with|スター*)"}))
        end
      end

      context "that is suffix match" do
        subject(:query) { z.build_query({search_condition: {"店舗名" => {"ends with" => "バックス"}}}) }
        it "should convert searchCondition => (Field|ends with|*word)" do
          expect(query).to eq(predefined_query.merge({"searchCondition" => "(店舗名|ends with|*バックス)"}))
        end
      end

      context "that is equal match" do
        subject(:query) { z.build_query({search_condition: {"店舗名" => {"=" => "スターバックス"}}}) }
        it "should convert searchCondition => (Field|=|word)" do
          expect(query).to eq(predefined_query.merge({"searchCondition" => "(店舗名|=|スターバックス)"}))
        end
      end
    end
  end

end
