class PaddleBillingTransactionCompleted
  def call(event)
    pay_charge = Pay::PaddleBilling::Charge.sync(event.id)
    if pay_charge && Pay.send_email?(:receipt, pay_charge)
      Pay.mailer.with(pay_customer: pay_charge.customer, pay_charge: pay_charge).receipt.deliver_later
    end

  end
end