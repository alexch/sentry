class EmailConfig

  def self.env(variable_name)
    ENV[variable_name] || begin
      $stderr.puts "Please set #{variable_name} in config/env.rb or using 'heroku config:add'"
    end
  end

  def self.get(env = Kernel.environment)

    # todo: move this into a YAML file

    gmail_imap = {
            :server => "imap.gmail.com",
            :port => 993,
            }

    hostito_imap = {
            :server => "secure02.secure-transact.net",
            :port => 993,
            :user => env('IMAP_USERNAME'),
            :secret => env('IMAP_PASSWORD'),
            }

    sendgrid = {
            :server         => "smtp.sendgrid.net",
            :port           => 587,
            :authtype       => :plain,
            :user           => env('SENDGRID_USERNAME'),
            :secret         => env('SENDGRID_PASSWORD'),
            :helo           => env('SENDGRID_DOMAIN'),
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
                :from_name => "Sentry",
                :outgoing => sendgrid,
                :incoming => hostito_imap
        }

      else
        # other emails, like deploy messages, get pushed through sendgrid
        {
                :from => 'sentry@cohuman.com',
                :outgoing => sendgrid << {
                        :debug => true,
                        },
                :incoming => hostito_imap
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
