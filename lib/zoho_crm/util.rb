require "httparty"
require "oj"
require "erb"

module ZohoCrm::Util

  def fetch(url, params)
    check_token

    query = build_query(params)

    response = http_get(url, query)

    valid_status_code?(response) or return []

    data = Oj.load(response.body)

    if error?(data) || nodata?(data)
      $stderr.puts message(data)
      return []
    end

    parse_fetched(data)
  end

  def update(url, params)
    check_token

    query = build_query(params)

    response = http_post(url, query)

    valid_status_code?(response) or return []

    data = Oj.load(response.body)

    if error?(data) || nodata?(data)
      $stderr.puts message(data)
      return []
    end

    parse_result(data)
  end

  def valid_status_code?(response)
    if response.code == 200
      true
    else
      $stderr.puts "Zoho API HTTP status code is [#{response.code}], body is [#{response.body}]."
      false
    end
  end

  def check_token
    if ZohoCrm.token.blank?
      raise RuntimeError, "Please set up your Zoho token firstly: ZohoCrm.token = \"blahblahblah\""
    end
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
      query["searchCondition"] = build_search_condition(query["searchCondition"])
    end

    if query.has_key?("xmlData") && query["xmlData"].is_a?(Hash)
      query["xmlData"] = build_xml_data(query["xmlData"])
    end

    query
  end

  def build_xml_data(pairs)
    xml_data = ""
    pairs.each do |key, val|
      xml_data << "<FL val=\"#{ERB::Util.html_escape(key)}\">#{ERB::Util.html_escape(val)}</FL>"
    end
    "<#{zoho_module_name}><row no=\"1\">#{xml_data}</row></#{zoho_module_name}>"
  end

  def build_search_condition(cond)
    field, cond_pair = cond.first
    op, val = cond_pair.first
    if op == "contains"
      val = "*#{val}*"
    elsif op == "starts with"
      val = "#{val}*"
    elsif op == "ends with"
      val = "*#{val}"
    end
    "(#{field}|#{op}|#{val})"
  end

  def zoho_module_name
    @zoho_module_name ||= self.to_s.demodulize.pluralize
  end

  def http_get(url, query)
    http_request(:get, url, query)
  end

  def http_post(url, query)
    http_request(:post, url, query)
  end

  def http_request(method, url, query)
    $stderr.puts "#{method.to_s.upcase} #{url} #{query}" if ZohoCrm.debug

    response = HTTParty.send(method, url, query: query)

    $stderr.puts "response: #{response}" if ZohoCrm.debug

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

  def parse_fetched(data)
    rows = data["response"]["result"][zoho_module_name]["row"]
    rows = [rows] if rows.class == Hash
    parse_fl(rows)
  end

  def parse_result(data)
    $stderr.puts data["response"]["result"]["message"] if ZohoCrm.debug
    rows = data["response"]["result"]["recorddetail"]
    rows = [rows] if rows.class == Hash
    parse_fl(rows)
  end

  def parse_fl(rows)
    rows.map do |row|
      if row["FL"].class == Array
        row["FL"].inject({}) { |h, r| h[r["val"]] = r["content"]; h }
      else row["FL"].class == Hash
        {row["FL"]["val"] => row["FL"]["content"]}
      end
    end
  end

end
