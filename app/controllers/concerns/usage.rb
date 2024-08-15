module Usage
  include CreditsCounter
  include DistributedLock

  extend ActiveSupport::Concern

  included do |base|
  end

  def credits_enough?
    raise NotImplementedError, "You must define #current_cost_credits in #{self.class}" unless defined?(:current_cost_credits)
    with_redis_lock(current_user.id) do
      (left_credits(current_user) >= current_cost_credits) || subscription_valid?
    end
  end

  module ClassMethods
  end

  private

  def has_payment?
    ENV.fetch('HAS_PAYMENT') == 'true' ? true : false
  end

  def account_confirmed?
    current_user.confirmed?
  end

  def subscription_valid?
    current_user.subscriptions.last&.active?
  end
end
