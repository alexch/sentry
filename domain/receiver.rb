require 'mail'
require 'net/imap'
require 'openssl'

require 'exception_reporting'

# receives email messages
class Receiver
  include ExceptionReporting

  attr_reader :config, :debug

  def initialize(opts = {}, &block)
    @config = !!opts[:config]
    @debug = !!opts[:debug]
    @processor = block
  end

  def config
    @config || EmailConfig.get
  end

  # todo: figure out how to test
  def scan(&block)
    @processor = block if block
    incoming_config = config.incoming
    if incoming_config.nil?
      logger.error("Not scanning for incoming mail, since environment is '#{Kernel.environment}'")
      return
    end

    say "Starting scan at #{Time.now}"
    c,e,n = nil,nil

    begin
      imap = Net::IMAP.new(incoming_config.server, incoming_config.port, true)
      imap.login(incoming_config.user, incoming_config.secret)
      imap.select('INBOX')
      messages = imap.search(["NOT", "DELETED"])
      n = messages.size
      c = e = 0
      messages.each do |message_id|
        received_message = nil
        rfc822 = imap.fetch(message_id, "RFC822")[0].attr["RFC822"]
        begin
          received_message = receive(rfc822)
          say "Processed message #{received_message.mail.subject}"
          c += 1
        rescue Exception => exception
          # todo: move message into an "error" folder so it doesn't get reprocessed, but don't delete it
          report_exception(exception)
          say "Error processing message #{message_id}: #{exception.class.name}: #{exception.message}"
          e += 1
        ensure
          if received_message && received_message.delete?
            say "Deleting message #{message_id}"
            imap.store(message_id, "+FLAGS", [:Deleted])
          end
        end
      end

      imap.close # Sends a CLOSE command to close the currently selected mailbox. The CLOSE command permanently removes from the mailbox all messages that have the \Deleted flag set.
      imap.logout
      imap.disconnect
    # NoResponseError and ByeResponseError happen often when imap'ing
    rescue Net::IMAP::NoResponseError, Net::IMAP::ByeResponseError, Errno::ENOTCONN
      # ignore
    rescue Exception => e
      report_exception(e)
    end
    say "Processed #{c.inspect} of #{n.inspect} emails received (#{e} errors)."
  end

  def receive(rfc822)
    say "Received email:\n#{rfc822}" if @debug
    received_message = ReceivedMessage.new(rfc822, config)
    @processor.call received_message
    received_message
  end

  # Run a scan, then enqueue as a DelayedJob 20 seconds into the future
  # To start this process off, do "Receiver.new.perform" from "heroku console"
  # To kill the job, run "Delayed::Job.last.destroy" (and hope you're quick enough)
  def perform
    scan
    Delayed::Job.enqueue self, 0, Time.now.utc + 20.seconds  # requeue for next time
    # todo: save the job id somewhere
  end

  def say message
    puts "#{Time.now} - #{message}" # was: logger.info(message) but that wasn't working
  end

end
