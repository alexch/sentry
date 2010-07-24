class Hash

  # alias shovel to merge
  alias :<< :merge

  # turns a hash into a hash
  def remap
    # This is Ruby magic for turning a hash into an array into a hash again
    Hash[*self.map do |key, value|
      yield key, value
    end.compact.flatten]
  end



  #todo: escaping/unescaping of param values

  # converts a hash into CGI parameters
  def to_params
    elements = []
    keys.size.times do |i|
      elements << "#{keys[i].to_s}=#{CGI::escape values[i].to_s}"
    end
    elements.join('&')
  end

  # converts CGI parameters into a hash
  def self.from_params(params)
    result = {}
    params.split('&').each do |element|
      element = element.split('=')
      result[element[0].to_s] = CGI::unescape(element[1])
    end
    result
  end

  def stringify_keys!
    keys.each do |key|
      self[key.to_s] = delete(key)
    end
    self
  end
  
end
