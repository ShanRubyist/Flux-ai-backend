module CreditsCounter
  extend ActiveSupport::Concern

  included do |base|
  end

  def total_used_credits(user)
    usage_classes.inject(0) { |sum, item| sum + used_credits(user, item) }
  end

  def total_credits(user)
    user.charges
        .where("amount_refunded is null or amount_refunded = 0")
        .inject(0) { |sum, item| sum + item.metadata.fetch("credits").to_i }
  end

  def left_credits(user)
    credits = total_credits(user) - total_used_credits(user) + (ENV.fetch('FREEMIUM_CREDITS') { 0 }).to_i

    credits = 0 if credits < 0
    return credits
  end

  def used_credits(user, usage_klass_name)
    # TODO: refactor
    user.send(usage_klass_name)
        .where("replicated_calls.data->>'status' = ?", 'succeeded')
        .sum(:cost_credits)
  end

  def usage_classes
    usage_classes_str = ENV.fetch('USAGE_CLASSES') { '' }
    usage_classes_str.split(',')
  end

  module ClassMethods
  end
end
