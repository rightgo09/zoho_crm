require "httparty"

module ZohoCrm::Util

  def fetch(url, params)
    if ZohoCrm.token.blank?
      raise RuntimeError, "Please set up your Zoho token firstly: ZohoCrm.token = \"blahblahblah\""
    end

    query = build_query(params)
    HTTParty.get(url, query: query)
  end

  def build_url
    # called method name
    action = caller.first.split(' ')[1].delete('`').delete("'").camelize(:lower)
    "https://crm.zoho.com/crm/private/json/#{zoho_module_name}/#{action}"
  end

  def build_query(params)
    query = Hash[params.map { |k, v| [k.to_s.camelize(:lower), v] }].merge(
      "authtoken" => ZohoCrm.token,
      "scope" => "crmapi",
    )

    if query["selectColumns"].present? && query["selectColumns"].is_a?(Array)
      query["selectColumns"] = zoho_module_name+"("+query["selectColumns"].join(",")+")"
    end

    query
  end

  def zoho_module_name
    self.to_s.demodulize.pluralize
  end

end
