class PaddleBillingChargeRefunded
  def call(event)
    return unless event.action == 'refund'

    pay_charge = Pay::PaddleBilling::Charge.sync(event.transaction_id, object: event)

    if pay_charge && Pay.send_email?(:refund, pay_charge)
      Pay.mailer.with(pay_customer: pay_charge.customer, pay_charge: pay_charge).refund.deliver_later
    end
  end
end