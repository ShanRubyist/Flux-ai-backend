class UsageController < ApplicationController
  before_action :authenticate_user!
  before_action :check_authorization, only: :predict

  private

  def check_authorization
    authorize :usage, :create?
  end

end