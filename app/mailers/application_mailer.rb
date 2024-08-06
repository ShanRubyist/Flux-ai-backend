class ApplicationMailer < ActionMailer::Base
  default from: "#{ENV['APPLICATION_NAME']} <#{ENV['EMAIL_FROM']}>"
  layout "mailer"
end