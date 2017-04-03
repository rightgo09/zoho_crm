%w[
  Lead
  Account
  Contact
  Potential
  Campaign
  Case
  Solution
  Product
  PriceBook
  Quote
  Invoice
  SalesOrder
  Vendor
  PurchaseOrder
  Event
  Task
  Call
].each do |module_name|
  ZohoCrm.const_set(module_name, Module.new {
    extend ZohoCrm::Util
    class << self
      %w[
        get_my_records get_records
        get_record_by_id
        get_cv_records
        get_search_records
        get_search_records_by_pdc
        get_related_records
      ].each do |method_name|
        define_method(method_name) do |params = {}|
          url = build_url(__method__)
          fetch(url, params)
        end
      end

      def insert_records(params = {})
        url = build_url(__method__)
        insert(url, params)
      end

      def update_records(params = {})
        url = build_url(__method__)
        update(url, params)
      end

      def delete_records(params = {})
        url = build_url(__method__)
        delete(url, params)
      end
    end
  })
end
