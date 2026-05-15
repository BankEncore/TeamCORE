# frozen_string_literal: true

class SessionsController < ApplicationController
  layout "minimal"

  def new
  end

  def create
    email = params[:email].to_s.strip.downcase
    password = params[:password]
    user = User.find_by(email: email)

    if user&.authenticate(password.to_s)
      session[:user_id] = user.id
      redirect_to resolve_post_login_destination_for(user), notice: "Signed in successfully."
      return
    end

    flash.now[:alert] = "Invalid email or password."
    render :new, status: :unprocessable_entity
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Signed out."
  end

  private

  def resolve_post_login_destination_for(user)
    permitted = user.agencies.load

    case permitted.size
    when 0
      session.delete(:current_agency_id)
      admin_root_path
    when 1
      session[:current_agency_id] = permitted.first.id
      admin_root_path
    else
      aids = permitted.map(&:id)
      cid = session[:current_agency_id]
      unless cid.present? && aids.include?(cid.to_i)
        session.delete(:current_agency_id)
        admin_agency_context_path
      else
        admin_root_path
      end
    end
  end
end
