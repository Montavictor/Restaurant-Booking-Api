class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  # GET /api/v1/signup
  def create
    user = User.new(user_params)

    if user.save
      sign_in(user) # This triggers Devise callbacks including JWT dispatch

      render json: {
        message: "Signed up successfully.",
        user: user.slice(:id, :email, :first_name, :last_name),
        token: request.env["warden-jwt_auth.token"]
      }, status: :ok
    else
      render json: {
        message: "Sign up failed.",
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :email,
      :password,
      :password_confirmation,
      :first_name,
      :last_name
    )
  end
end
