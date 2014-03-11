require "httparty"
require "oj"

module ZohoCrm::Util

  def fetch(url, params)
    if ZohoCrm.token.blank?
      raise RuntimeError, "Please set up your Zoho token firstly: ZohoCrm.token = \"blahblahblah\""
    end

    query = build_query(params)

    response = HTTParty.get(url, query: query)

    results = []

    unless response.code == 200
      $stderr.puts "Zoho API HTTP status code is [#{response.code}], body is [#{response.body}]."
      return results
    end

    data = Oj.load(response.body)

    if data["response"].has_key?("nodata")
      $stderr.puts data["response"]["nodata"]["message"]
      return results
    end

    rows = data["response"]["result"]["Potentials"]["row"]
    rows = [rows] if rows.class == Hash
    results = rows.map do |row|
      if row["FL"].class == Array
        row["FL"].inject({}) { |h, r| h[r["val"]] = r["content"]; h }
      else row["FL"].class == Hash
        {row["FL"]["val"] => row["FL"]["content"]}
      end
    end

    results
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
    @zoho_module_name ||= self.to_s.demodulize.pluralize
  end

end
