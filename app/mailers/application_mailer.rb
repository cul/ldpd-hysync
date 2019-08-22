class ApplicationMailer < ActionMailer::Base
  default from: HYSYNC['default_sender_email_address']
  layout 'mailer'

  def marc_sync_error_email
    mail(
      to: params[:to],
      subject: params[:subject],
      body: "One or more errors were encountered during MARC sync:\n\n" + params[:errors].join("\n") + "\n",
    	content_type: 'text/plain'
    )
  end
end
