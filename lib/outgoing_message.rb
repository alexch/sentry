# == Schema Information
#
# Table name: outgoing_messages
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  task_id    :integer
#  smtp_id    :string(255)
#  message_id :string(255)
#  project_id :integer
#
# Indexes
#
#  index_outgoing_messages_on_message_id  (message_id)
#

require 'rubygems'
require 'exception_reporting'
require 'mail'

# OutgoingMessage - minimal emailer
#
# Author: Alex Chaffee <alex@cohuman.com>
#
# Usage:
#
# OutgoingMessage.new(:from => 'awesomeapp@gmail.com', :to => ['alexch@gmail.com', 'alex@stinky.com'], :subject => 'ohai', :body => "lol\ncats").deliver
#
# OutgoingMessage.fake - turn on test mode
#
# OutgoingMessage.sent - list of all emails sent in test mode
#
# OutgoingMessage.print_fakes - for development mode - prints emails to console if in fake mode
#
# TODO: read config from a file
#
class OutgoingMessage
  include ExceptionReporting

  # todo: move the faking stuff into a separate Mailman (delivery strategy object)

  @@fake = false
  @@print_fakes = false
  @@host = "example.com"

  # activates "fake mode" and clears the sent queue
  def self.fake(on = true)
    @@fake = on
    clear
  end

  def self.clear
    @@sent = []
  end

  def self.fake?
    @@fake
  end

  # if in fake mode, prints fake messages to console
  def self.print_fakes
    @@print_fakes = true
  end

  # if in fake mode, returns messages in order they were sent
  def self.sent
    @@sent
  end

  def self.from_name
    # todo: read
  end

  def self.host=(value)
    @@host = value
  end

  def self.url(path = "/", params = nil)
    path = "/#{path}" unless path[0..0] == "/"
    "http://#{@@host}#{path}" + (params ? "?#{params.to_params}" : "")
  end

  MAXIMUM_NUMBER_OF_TRIES = 2

  attr_reader :from, :sender, :reply_to, :subject, :bcc, :in_reply_to, :body, :category, :config

  def initialize(options)
    @config = options[:config] || EmailConfig.get

    [:from, :sender, :reply_to, :to, :bcc, :subject, :body, :in_reply_to, :category].each do |var|
      instance_variable_set("@#{var}", options[var])
    end

    @from ||= if @config.from_name
                "#{@config.from} (#{OutgoingMessage.from_name})"
              else
                @config.from
              end
    
    [:to, :subject, :body].each do |key|
      raise "missing required field '#{key}'" if options[key].nil?
    end
  end

  def to
    @to = [*@to].compact
  end

  def body_to_text
    if body.is_a? Widget
      body.to_text.strip
    else
      body.to_s
    end
  end

  def body_to_html
    html = if body.is_a? Widget
      body.to_pretty(:max_length => 72)
    else
      newline_to_break(body.to_s)
    end

    html.gsub(/(href=[\"\'])\//i) do |m|
      $1 + OutgoingMessage.url("/")
    end
  end

  def newline_to_break(string)
    string.gsub(/\n/, '<br>')
  end

  def text_part
    text_part = Mail::Part.new
    text_part.body = body_to_text
    return text_part
  end

  def html_part
    html_part = Mail::Part.new
    html_part.content_type = 'text/html; charset=UTF-8'
    html_part.body = body_to_html
    return html_part
  end

  def assemble_mail
    if @mail
      raise "you can only assemble the mail once"
    end

    @mail = Mail.new
    @mail.to = to
    @mail.bcc = bcc if bcc
    @mail.from = from
    @mail.subject = subject
    @mail.sender = sender if sender
    @mail.reply_to = reply_to if reply_to
    @mail['In-Reply-To'] = in_reply_to if in_reply_to
    @mail['X-SMTPAPI'] = "{\"category\": \"#{category}\"}" if category
    @mail.text_part = text_part
    @mail.html_part = html_part

    @mail
  end

  def mail
    assemble_mail unless @mail
    @mail
  end

  def send_email(outgoing_config)
    mail.ready_to_send! # constructs message_id and other required fields
    if @@fake
      logger.info("Sending fake email: to=#{to} subject=#{subject}")
      if @@print_fakes
        puts "[[ Pretending to send email:"
        puts mail.to_s
        puts "]]"
      end
      @@sent << self
    else
      logger.info("Sending email: to=#{to} subject=#{subject} via #{outgoing_config.server}")
      Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
      smtp = Net::SMTP.new(outgoing_config.server, outgoing_config.port)
      debug = nil
      if outgoing_config.debug
        debug = StringIO.new
        smtp.set_debug_output(debug)
      end
      smtp.start(outgoing_config.helo, outgoing_config.user, outgoing_config.secret, outgoing_config.authtype) do |smtp|
        smtp_sender = [sender || from].flatten.first
        # using mail.destinations instead of to gets the mail to the bcc'd addresses
        smtp.send_message mail.to_s, smtp_sender, mail.destinations
      end
      if outgoing_config.debug
        puts debug.string
      end
    end
    mail
  end

  def deliver
    if to.empty?
      logger.warn("Not delivering message since to is empty: subject=#{subject}")
      return
    end
    tries = 0
    3.times do
      begin
        tries += 1
        send_email(config.outgoing)
        return
      rescue Exception => e
        handle_error(e, tries)
      end
    end
  end

  private

  def handle_error(error, tries)
    if (tries > MAXIMUM_NUMBER_OF_TRIES)
      report_exception error
      raise error
    end
  end

  def track_message?
    !!self.task || !!self.project
  end

end
