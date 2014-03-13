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
end
