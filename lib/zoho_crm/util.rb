require "httparty"
require "oj"

module ZohoCrm::Util

  def fetch(url, params)
    if ZohoCrm.token.blank?
      raise RuntimeError, "Please set up your Zoho token firstly: ZohoCrm.token = \"blahblahblah\""
    end

    query = build_query(params)

    response = http_get(url, query)

    unless response.code == 200
      $stderr.puts "Zoho API HTTP status code is [#{response.code}], body is [#{response.body}]."
      return []
    end

    data = Oj.load(response.body)

    if error?(data) || nodata?(data)
      $stderr.puts message(data)
      return []
    end

    parse(data)
  end

  def build_url(method_name)
    action = method_name.to_s.camelize(:lower)
    "https://crm.zoho.com/crm/private/json/#{zoho_module_name}/#{action}"
  end

  def build_query(params)
    query = Hash[params.map { |k, v| [k.to_s.camelize(:lower), v] }].merge(
      "authtoken" => ZohoCrm.token,
      "scope" => "crmapi",
    )

    if query.has_key?("selectColumns") && query["selectColumns"].is_a?(Array)
      query["selectColumns"] = zoho_module_name+"("+query["selectColumns"].join(",")+")"
    end

    if query.has_key?("searchCondition") && query["searchCondition"].is_a?(Hash)
      field, cond_pair = query["searchCondition"].first
      op, val = cond_pair.first
      if op == "contains"
        val = "*#{val}*"
      elsif op == "starts with"
        val = "#{val}*"
      elsif op == "ends with"
        val = "*#{val}"
      end
      query["searchCondition"] = "(#{field}|#{op}|#{val})"
    end

    query
  end

  def zoho_module_name
    @zoho_module_name ||= self.to_s.demodulize.pluralize
  end

  def http_get(url, query)
    if ZohoCrm.debug
      $stderr.puts "url: #{url}"
      $stderr.puts "query: #{query}"
    end

    response = HTTParty.get(url, query: query)

    if ZohoCrm.debug
      $stderr.puts "response: #{response}"
    end

    response
  end

  def nodata?(data)
    data["response"].has_key?("nodata")
  end

  def error?(data)
    data["response"].has_key?("error")
  end

  def message(data)
    if error?(data)
      data["response"]["error"]["message"]
    elsif nodata?(data)
      data["response"]["nodata"]["message"]
    end
  end

  def parse(data)
    rows = data["response"]["result"]["Potentials"]["row"]
    rows = [rows] if rows.class == Hash
    rows.map do |row|
      if row["FL"].class == Array
        row["FL"].inject({}) { |h, r| h[r["val"]] = r["content"]; h }
      else row["FL"].class == Hash
        {row["FL"]["val"] => row["FL"]["content"]}
      end
    end
  end

end
