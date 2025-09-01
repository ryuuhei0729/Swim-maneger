class ErrorsController < ApplicationController
  skip_before_action :authenticate_api_user!

  def not_found
    respond_to do |format|
      format.html { render status: :not_found }
      format.json { render json: { success: false, message: 'Not Found' }, status: :not_found }
      format.all { head :not_found }
    end
  end

  def internal_server_error
    respond_to do |format|
      format.html { render status: :internal_server_error }
      format.json { render json: { error: 'Internal Server Error' }, status: :internal_server_error }
      format.all { head :internal_server_error }
    end
  end

  def unprocessable_entity
    respond_to do |format|
      format.html { head :unprocessable_entity }
      format.json { render json: { success: false, message: 'Unprocessable Entity' }, status: :unprocessable_entity }
      format.all { head :unprocessable_entity }
    end
  end
end
