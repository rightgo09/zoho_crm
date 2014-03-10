module ZohoCrm::Potential
  extend ZohoCrm::Util

  def self.get_my_records(params = {})
    url = build_url(__method__.to_s.camelize(:lower))
    fetch(url, params)
  end

end
