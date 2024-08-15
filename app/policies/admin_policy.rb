class AdminPolicy < ApplicationPolicy
  def initialize(user, _record)
    @user = user
  end

  def admin?
    return @user.email == ENV.fetch('ADMIN_USER_EMAIL')
  end
end
