require 'mail'
require 'exception_reporting'

class ReceivedMessage
  include ExceptionReporting

  attr_reader :mail, :config

  def initialize(rfc822, config = EmailConfig.get)
    @config = config
    @mail = Mail.new(rfc822)
    @rfc822 = rfc822
    unless valid?
      raise "invalid email: #{@problem}"
    end
  end

  def subject
    strip_res(mail.subject || "")
  end

  def body
    body = find_body
    body = body.
      gsub(/\r\n/, "\n") # remove network newlines
    body.strip!
    return body
  end

  def fwd?(line)
    line.blank? || line =~ /^>/ || line.match(/^On .*:$/)
  end

  def find_body
    if mail.multipart?
      mail.parts.each do |part|
        # http://en.wikipedia.org/wiki/MIME#Content-Disposition
        # http://www.oreillynet.com/mac/blog/2005/12/forcing_thunderbird_to_treat_o.html
        next if part["content-disposition"] =~ "attachment"
        if part["content-type"].to_s =~ %r(^text/plain)
          return part.body.to_s
        elsif part["content-type"].to_s =~ %r(^multipart/alternative)
          return part.text_part.body.decoded
        end
      end
      mail.parts.first.body.to_s # depends on part-sort-order putting text/plain first
    else
      mail.body.to_s
    end
  end

  def attachments
    mail.attachments
  end

  def valid?
    if mail.from.nil?
      @problem = "from was empty"
      report_exception("bad email received: #{@problem}")
      return false
    end

    from = mail.from.first.downcase
    if from == config.from # somehow we sent a message to ourself
      @problem = "from me"
      return false
    end

    return true
  end

  def recipients
    ([mail.to] + [mail.cc] + [mail["Delivered-To"].to_s]).flatten.compact
  end

  def delete
    @delete = true
  end

  def delete?
    !!@delete # force to true or false
  end

  protected
  def strip_res(subject)
    subject.gsub(/^((re:|fwd:) *)*/i, '').strip
  end

  def process_message_ids(* args)
    args.join(", ").split(/, ?/).map do |s|
      s.strip.gsub(/^</, '').gsub(/>$/, '')
    end.reject do |s|
      s.blank?
    end.compact.uniq
  end

end
