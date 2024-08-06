Pay.setup do |config|
  # For use in the receipt/refund/renewal mailers
  config.business_name = ENV.fetch('BUSINESS_NAME')
  config.business_address = ENV.fetch('BUSINESS_ADDRESS')
  config.application_name = ENV.fetch('APPLICATION_NAME')
  config.support_email = "#{ENV['BUSINESS_NAME']} <#{ENV['EMAIL_FROM']}>"

  config.default_product_name = ENV.fetch('DEFAULT_PRODUCT_NAME')
  config.default_plan_name = ENV.fetch('DEFAULT_PLAN_NAME')

  config.automount_routes = true
  config.routes_path = "/pay" # Only when automount_routes is true
  # All processors are enabled by default. If a processor is already implemented in your application, you can omit it from this list and the processor will not be set up through the Pay gem.
  config.enabled_processors = [:stripe, :braintree, :paddle_billing, :paddle_classic]

  # To disable all emails, set the following configuration option to false:
  config.send_emails = true

  # All emails can be configured independently as to whether to be sent or not. The values can be set to true, false or a custom lambda to set up more involved logic. The Pay defaults are show below and can be modified as needed.
  config.emails.payment_action_required = true
  config.emails.payment_failed = true
  config.emails.receipt = true
  config.emails.refund = true
  # This example for subscription_renewing only applies to Stripe, therefore we supply the second argument of price
  config.emails.subscription_renewing = ->(pay_subscription, price) {
    (price&.type == "recurring") && (price.recurring&.interval == "year")
  }
  config.emails.subscription_trial_will_end = true
  config.emails.subscription_trial_ended = true

  # Customize who receives emails. Useful when adding additional recipients other than the Pay::Customer. This defaults to the pay customer's email address.
  # config.mail_to = ->(mailer, params) { "#{params[:pay_customer].customer_name} <#{params[:pay_customer].email}>" }

  # Customize mail() arguments. By default, only includes { to: }. Useful when you want to add cc, bcc, customize the mail subject, etc.
  # config.mail_arguments = ->(mailer, params) {
  #   {
  #     to: Pay.mail_recipients.call(mailer, params)
  #   }
  # }
end

ActiveSupport.on_load(:pay) do
  Pay::Webhooks.delegator.subscribe "paddle_billing.transaction.completed", PaddleBillingTransactionCompleted.new
  Pay::Webhooks.delegator.subscribe "paddle_billing.adjustment.updated", PaddleBillingChargeRefunded.new
end
