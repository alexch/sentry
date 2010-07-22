class EmailConfig

  def self.get(env = Kernel.environment)

    # todo: move this into a YAML file

    gmail_imap = {
            :server => "imap.gmail.com",
            :port => 993,
            }

    hostito_imap = {
            :server => "secure02.secure-transact.net",
            :port => 993,
            }

    sendgrid = {
            :server         => "smtp.sendgrid.net",
            :port           => 587,
            :authtype       => :plain,
            :user           => ENV['SENDGRID_USERNAME'],
            :secret         => ENV['SENDGRID_PASSWORD'],
            :helo           => ENV['SENDGRID_DOMAIN'],
            }

    EmailConfig.new case env

      when "test"
        {
                :from => 'sentry@example.com',
                :outgoing => {
                        :server => "smtp.example.com",
                        :port => 587,
                        :authtype => :plain,
                        :user => "testuser",
                        :secret => "password",
                        :helo => "example.com",
                        },
                :incoming => {
                        :server => "imap.example.com",
                        :port => 993,
                        :user => "testuser",
                        :secret => "password",
                        }
        }

      when "production"
        {
                :from => 'sentry@cohuman.com',
                :outgoing => sendgrid,
                :incoming => hostito_imap << {
                        :user => ENV['IMAP_USER'],
                        :secret => ENV['IMAP_SECRET'],
                        }
        }

      else
        # other emails, like deploy messages, get pushed through sendgrid
        {
                :from => 'dev@cohuman.com',
                :outgoing => sendgrid << {
                        :debug => true,
                        },
                :incoming => nil
        }
    end

  end

  def initialize(data)
    @data = data.remap do |k, v|
      if v.is_a?(Hash)
        [k, EmailConfig.new(v)]
      else
        [k, v]
      end
    end
  end

  def method_missing(method_name, * args)
    @data[method_name]
  end

  def [](key)
    @data[key]
  end
end
