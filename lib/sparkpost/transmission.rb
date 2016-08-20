require 'net/http'
require 'uri'
require_relative '../core_extensions/object'
require_relative 'request'
require_relative 'exceptions'

module SparkPost
  class Transmission
    include Request

    def initialize(api_key, api_host)
      @api_key = api_key
      @api_host = api_host
      @base_endpoint = "#{@api_host}/api/v1/transmissions"
    end

    def send_payload(data = {}, url = endpoint, method = 'POST')
      request(url, @api_key, data, method)
    end

    def send_message(to, from, subject, html_message = nil, campaign_id = "", **options)
      # TODO: add validations for to, from
      html_message = content_from(options, :html) || html_message
      text_message = content_from(options, :text) || options[:text_message]
      content_options = options.delete(:content) || {}

      if html_message.blank? && text_message.blank?
        raise ArgumentError, 'Content missing. Either provide html_message or
         text_message in options parameter'
      end

      options_from_args = {
        recipients: prepare_recipients(to),
        content: content_options.merge(
          from: from,
          subject: subject,
          text: options.delete(:text_message),
          html: html_message
        ),
        options: {}
      }

      options_from_args["campaign_id"] = campaign_id if !campaign_id.blank?

      options.merge!(options_from_args) { |_k, opts, _args| opts }
      add_attachments(options)

      send_payload(options)
    end

    def prepare_recipients(recipients)
      recipients = [recipients] unless recipients.is_a?(Array)
      recipients.map { |recipient| prepare_recipient(recipient) }
    end

    private

    def add_attachments(options)
      if options[:attachments].present?
        options[:content][:attachments] = options.delete(:attachments)
      end
    end

    def prepare_recipient(recipient)
      if recipient.is_a?(Hash)
        raise ArgumentError,
              "email missing - '#{recipient.inspect}. It has to be {:address => {:email => 'example@example.com'}} at least!!'" unless recipient[:address][:email]
        return recipient ## This approach allow to send more data in recipients object #Look documentation at Sparkpost API
      else
        { address: { email: recipient } }
      end
    end

    def content_from(options, key)
      (options || {}).fetch(:content, {}).fetch(key, nil)
    end
  end
end
