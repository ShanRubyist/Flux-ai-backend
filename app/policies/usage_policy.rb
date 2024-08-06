class UsagePolicy < ApplicationPolicy
  include CreditsCounter
  include DistributedLock

  def initialize(user, _record)
    @user = user
  end

  def create?
    return true if !has_payment? || credits_enough?
  end

  private

  def has_payment?
    ENV.fetch('HAS_PAYMENT') == 'true' ? true : false
  end

  def account_confirmed?
    @user.confirmed?
  end

  def subscription_valid?
    @user.subscriptions.last&.active?
  end

  def has_left_credits?
    left_credits(@user) > 0
  end

  def credits_enough?
    with_redis_lock(@user.id) do
      has_left_credits? || subscription_valid?
    end
  end
end
