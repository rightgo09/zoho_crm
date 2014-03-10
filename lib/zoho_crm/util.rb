require "httparty"

module ZohoCrm::Util

  def fetch(url, params)
    if ZohoCrm.token.blank?
      raise RuntimeError, "Please set up your Zoho token firstly: ZohoCrm.token = \"blahblahblah\""
    end

    query = build_query(params)
    HTTParty.get(url, query: query)
  end

  def build_url(action)
    "https://crm.zoho.com/crm/private/json/#{self.to_s.demodulize}s/#{action}"
  end

  def build_query(params)
    params.merge(authtoken: ZohoCrm.token, scope: "crmapi")
  end

end
