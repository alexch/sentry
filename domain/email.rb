class Email
  include DataMapper::Resource
  property :id, Serial
  property :address, String, :format => :email_address
  validates_uniqueness_of :address
end
