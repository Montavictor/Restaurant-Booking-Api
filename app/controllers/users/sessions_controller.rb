class Users::SessionsController < Devise::SessionsController
  respond_to :json

  # POST /api/v1/login
  def create
    user_params = params[:user] || params
    user = User.find_by(email: user_params[:email])

    if user&.valid_password?(user_params[:password])
      sign_in(user) # Triggers Devise and JWT token dispatch
      render json: {
        message: "Login success",
        user: user.slice(:id, :email, :first_name, :last_name),
        token: request.env["warden-jwt_auth.token"]
      }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  # DELETE /api/v1/logout
  def destroy
    token = request.headers["Authorization"]&.split(" ")&.last

    begin
      jwt_payload = JWT.decode(token, Rails.application.credentials.devise[:jwt_secret_key]).first
      JwtDenylist.create!(jti: jwt_payload["jti"], exp: Time.at(jwt_payload["exp"]))

      render json: { message: "Logout success" }, status: :ok
    rescue JWT::DecodeError => e
      Rails.logger.warn("JWT decode failed: #{e.message}")
      render json: { error: "Invalid token" }, status: :unauthorized
    end
  end

  private

  def respond_to_on_destroy
    render json: { message: "Logged out" }, status: :ok
  end
end
