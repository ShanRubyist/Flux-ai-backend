class Api::V1::AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :check_authorization!

  def check_authorization!
    authorize :admin, :admin?
  end
end