# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    redirect_to(current_user ? admin_root_path : login_path)
  end
end
