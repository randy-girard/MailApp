require 'net/imap'
require 'mail'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_filter :open_imap
  
  private
  
  def open_imap
    Rails.logger.info ENV.inspect
    
    @folders = []
    @messages = []
    
    if @imap.nil?
      @imap = Net::IMAP.new(ENV["IMAP_HOST"], 993, usessl = true, certs = nil, verify = false)
      @imap.login(ENV["IMAP_USER"], ENV["IMAP_PASSWORD"])
      begin
        @folders = @imap.list('*', '*')
        @folder = params[:folder_id]
        
        if params[:id].present?
          @imap.select(params[:folder_id])
          msg = @imap.fetch(params[:id].to_i,'RFC822')[0].attr['RFC822']
          mail = Mail.read_from_string msg
          if mail
            @message =
            {
              :id => params[:id],
              :from => mail.from,
              :subject => mail.subject,
              :date => mail.date,
              :text => mail.text_part.try(:body),
              :html => mail.html_part.try(:body),
              :raw => mail
            }
          else
            @message = {}
          end
        elsif params[:folder_id].present?
          @imap.select(params[:folder_id])
          @messages = @imap.search(["ALL"]).map do |message_id|
            msg = @imap.fetch(message_id,'RFC822')[0].attr['RFC822']
            mail = Mail.read_from_string msg
            if mail
              {
                :id => message_id,
                :from => mail.from,
                :subject => mail.subject,
                :date => mail.date,
                :text => mail.text_part.try(:body),
                :html => mail.html_part.try(:body),
                :raw => mail
              }
            else
              {}
            end
          end
        end
      ensure
        @imap.logout
        @imap.disconnect
      end
    end
  end
end
