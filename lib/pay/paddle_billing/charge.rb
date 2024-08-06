module Pay
  module PaddleBilling
    class Charge
      def self.sync(charge_id, object: nil, try: 0, retries: 1)
        # Skip loading the latest charge details from the API if we already have it
        object ||= ::Paddle::Transaction.retrieve(id: charge_id)

        # Ignore charges without a Customer
        return if object.customer_id.blank?

        pay_customer = Pay::Customer.find_by(processor: :paddle_billing, processor_id: object.customer_id)
        return unless pay_customer

        if object.action == 'refund'
          return unless object.status == "approved"

          attrs = { amount_refunded: object.totals.subtotal }

          if (pay_charge = pay_customer.charges.find_by(processor_id: object.transaction_id))
            pay_charge.with_lock do
              pay_charge.update!(attrs)
            end
            pay_charge
          end
        else
          # Ignore transactions that aren't completed
          return unless object.status == "completed"

          # Ignore transactions that are payment method changes
          # But update the customer's payment method
          if object.origin == "subscription_payment_method_change"
            Pay::PaddleBilling::PaymentMethod.sync(pay_customer: pay_customer, attributes: object.payments.first)
            return
          end

          attrs = {
            amount: object.details.totals.grand_total,
            created_at: object.created_at,
            currency: object.currency_code,
            metadata: {
              id: object.details.line_items&.first&.id,
              credits: calculate_credits(object.details.line_items)
            },
            subscription: pay_customer.subscriptions.find_by(processor_id: object.subscription_id)
          }

          if (details = Array.wrap(object.payments).first&.method_details)
            case details.type.downcase
            when "card"
              attrs[:payment_method_type] = "card"
              attrs[:brand] = details.card.type
              attrs[:exp_month] = details.card.expiry_month
              attrs[:exp_year] = details.card.expiry_year
              attrs[:last4] = details.card.last4
            when "paypal"
              attrs[:payment_method_type] = "paypal"
            end

            # Update customer's payment method
            Pay::PaddleBilling::PaymentMethod.sync(pay_customer: pay_customer, attributes: object.payments.first)
          end

          # Update or create the charge
          if (pay_charge = pay_customer.charges.find_by(processor_id: object.id))
            pay_charge.with_lock do
              pay_charge.update!(attrs)
            end
            pay_charge
          else
            pay_customer.charges.create!(attrs.merge(processor_id: object.id))
          end
        end

      end

      private

      def self.calculate_credits(items)
        items.inject(0) { |sum, item| sum + credit_of_price(item.price_id) * item.quantity }
      end

      def self.credit_of_price(price_id)
        credit = case price_id
                 when ENV.fetch('PRICE_1')
                   ENV.fetch('PRICE_1_CREDIT')
                 when ENV.fetch('PRICE_2')
                   ENV.fetch('PRICE_2_CREDIT')
                 when ENV.fetch('PRICE_3')
                   ENV.fetch('PRICE_3_CREDIT')
                 end
        
        return credit.to_i
      end
    end
  end
end