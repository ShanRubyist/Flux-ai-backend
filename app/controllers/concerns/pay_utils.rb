module PayUtils
  extend ActiveSupport::Concern

  included do |base|
  end

  def has_active_subscription?(user)
    user.subscriptions.select { |sub| sub.active? }.count > 0
  end

  def active_subscriptions(user)
    user.subscriptions.order('updated_at').select { |sub| sub.active? }
  end

  module ClassMethods
  end
end
