module ApiErrorHandler
  extend ActiveSupport::Concern
  
  included do
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  end
  
  private
  
  def record_not_found
    render json: { 
      error: "Resource not found",
      timestamp: Time.current.iso8601 
    }, status: :not_found
  end
  
  def handle_record_invalid(exception)
    render json: { 
      error: "Validation failed",
      details: exception.record.errors.full_messages,
      timestamp: Time.current.iso8601
    }, status: :unprocessable_entity
  end
  
  def handle_parameter_missing(exception)
    render json: { 
      error: "Missing required parameter: #{exception.param}",
      timestamp: Time.current.iso8601
    }, status: :bad_request
  end
end