class Hash

  # alias shovel to merge
  alias :<< :merge

  # turns a hash into a hash
  def remap
    # This is Ruby magic for turning a hash into an array into a hash again
    Hash[* self.map do |key, value|
      yield key, value
    end.compact.flatten]
  end

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

  # stolen from active_support
  def stringify_keys
    inject({}) do |options, (key, value)|
      options[key.to_s] = value
      options
    end
  end

  # stolen from active_support
  def stringify_keys!
    keys.each do |key|
      self[key.to_s] = delete(key)
    end
    self
  end

  # todo: test
  def -(other_hash)
    result = dup
    other_hash.keys.each do |key|
      result.delete(key)
    end
    result
  end

end
