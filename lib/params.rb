# allows a "params" DataMapper property to act as a Hash with some useful methods and semantics
# todo: make it a DM type so it can be named anything

module Params

  def self.included(resource)
    resource.class_eval do
      property :params, DataMapper::Property::Json
      before :save, :stringify_params
    end
  end

  def stringify_params
    attribute_set(:params, get_params.stringify_keys!)
  end

  # can be overridden by a Resource
  def default_params
    {}
  end

  def params
    p = get_params.dup
    p.instance_eval do
      def []=(key, value)
        raise "Sorry, but you can't modify the params object directly. Try obj.param(#{key.to_s.inspect}, #{value.inspect}) instead."
      end
    end
    p
  end

  # Usage:
  # param("foo")
  # calling param with one argument makes it act as a getter
  #
  # param("foo", "bar")
  # calling param with two arguments makes it act as a setter
  #
  # Params are always string keys, but this method accepts either string or symbol keys.
  #
  def param(* args)
    if args.length == 2
      key, value = args
      new_params = get_params # get_params needs to return a dup and re-set it so DM knows it's dirty
      new_params[key.to_s] = value
      attribute_set(:params, new_params)
    elsif args.length == 1
      key = args.first
      get_params[key.to_s]
    else
      raise ArgumentError, "param takes either one (getter) or two (setter) arguments"
    end
  end

  private

  def get_params
    p = attribute_get(:params)
    if p.nil?
      default_params
    else
      p.stringify_keys
    end
  end

end
