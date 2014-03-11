module ZohoCrm::Potential
  extend ZohoCrm::Util

  def self.get_my_records(params = {})
    url = build_url
    fetch(url, params)
  end

end
