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
    body = find_comment

    body = body.
      gsub(/\r\n/, "\n") # remove network newlines

#    if (mail['X-Mailer'] && (mail['X-Mailer'].to_s =~ /iPhone Mail/))
#      parts = body.split(/^Begin forwarded message:$/)
#      if parts.size == 2
#        body = parts.first + "Begin forwarded message:" + parts.last.gsub(/^> ?/, '')
#      end
#    end
#
#    body = body.
#      gsub(/^--+( *)$.*/m, '').# remove .sig
#      gsub(/^__+( *)$.*/m, '').# remove yahoo fwd
#      gsub(/<http:\/\/[^.]*.sendgrid.info[^>]*>/, '') # remove sendgrid rewrite links sent from staging
#
    body.strip!

    body = strip_fwd_lines(body)

    return body
  end

  def strip_fwd_lines(body)
    lines = body.split("\n")
    while !lines.empty? && fwd?(lines.last)
      lines.pop
    end

    if (lines.last =~ /^[^ ]*:$/ && lines[lines.size - 2] != /^On /)
      lines.pop
      lines.pop
    end

    lines.join("\n").strip
  end

  def fwd?(line)
    line.blank? || line =~ /^>/ || line.match(/^On .*:$/)
  end

  def find_comment
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
