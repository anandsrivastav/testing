class AuthenticationController < ApplicationController
  skip_before_action :authenticate_request

  def authenticate
    command = AuthenticateUser.call(params[:email], params[:password])
    if command.success?
      render json: { auth_token: command.result }
    else
      render json: { error: command.errors }, status: :unauthorized
    end
  end

  def authorize_token
    @current_user = AuthorizeApiRequest.call(params[:token]).result
    if @current_user.present?
      token = ::JsonWebToken.encode(user_id: @current_user.id)
      render json: { success: true, auth_token: token }, status: 200
    else
      render json: { error: 'Not Authorized. Provided token may be expired or already used.' }, status: 401 unless @current_user    
    end
  end

  def recover_password
    user = User.find_by_email(params[:email])
    if user.present?
      auth_token = ::JsonWebToken.encode(user_id: user.id)
      UserMailer.sendRecoveryEmail(user, auth_token).deliver
      render json: { success: true, message: "Please check your email. We have sent you a password recovery Link." }, status: 200
    else
      render json: { error: "Your email is not registered with us. Please verify." }, status: 200
    end
  end

end
