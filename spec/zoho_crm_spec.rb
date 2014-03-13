require 'spec_helper'

describe ZohoCrm do
  it 'should have a version number' do
    expect(ZohoCrm::VERSION).to_not be_nil
  end
end

describe ZohoCrm::Util do
  let(:z) { Class.new { extend ZohoCrm::Util } }

  describe "#build_url" do
    before { ZohoCrm.const_set("BlackCoffee", z) }
    it "should build url" do
      expect(z.build_url(:get_my_records)).to eq("https://crm.zoho.com/crm/private/json/BlackCoffees/getMyRecords")
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
    context "snake_case" do
      subject(:query) { z.build_query({new_format: 1}) }
      it "should convert camel case" do
        expect(query).to eq(predefined_query.merge({"newFormat" => 1}))
      end
    end
  end

end
