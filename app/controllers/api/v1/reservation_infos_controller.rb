class Api::V1::ReservationInfosController < ApplicationController
  include ApiErrorHandler
  
  before_action :set_reservation_info, only: [:show]
  
  # GET /reservation_infos
  def index
    @reservation_infos = fetch_reservation_infos
    
    render json: @reservation_infos.as_json(
      include: {
        booking_date: { only: [:id, :date, :is_lunch_available, :is_dinner_available] }
      },
      except: [:created_at, :updated_at]
    )
  end
  
  # GET /reservation_infos/1
  def show
    render json: @reservation_info.as_json(
      include: {
        booking_date: { only: [:id, :date, :is_lunch_available, :is_dinner_available] }
      },
      except: [:created_at, :updated_at]
    )
  end
  
  # POST /reservation_infos
  def create
    payment_service = PaymentService.new(reservation_info_params)
    result = payment_service.create_payment_intent
    
    if result[:success]
      render json: {
        stripe_client_secret: result[:client_secret],
        amount_info: result[:amount_info]
      }, status: :created
    else
      render json: { 
        error: result[:error],
        timestamp: Time.current.iso8601 
      }, status: :unprocessable_entity
    end
  end
  
  # POST /reservation_infos/confirm
  def confirm
    payment_service = PaymentService.new({})
    result = payment_service.confirm_payment(params[:payment_intent_id])
    
    if result[:success]
      render json: {
        message: result[:message],
        reservation_id: result[:reservation_id]
      }, status: result[:reservation_id] ? :created : :ok
    else
      render json: { 
        error: result[:error],
        details: result[:details],
        timestamp: Time.current.iso8601 
      }, status: :unprocessable_entity
    end
  end
  
  # POST /reservation_infos/cancel
  def cancel
    token = extract_cancellation_token
    return render_token_missing_error unless token.present?
    
    reservation = ReservationInfo.find_by(cancellation_token: token)
    return render_reservation_not_found_error unless reservation
    
    if reservation.cancelled?
      return render json: {
        message: "Reservation already cancelled",
        reservation_id: reservation.id,
        cancelled_at: reservation.updated_at.iso8601
      }, status: :ok
    end
    
    unless reservation.can_be_cancelled?
      return render json: {
        error: "Reservation cannot be cancelled within #{ReservationInfo::CANCEL_WINDOW_DAYS} days of the reservation date",
        last_cancellation_date: (reservation.reservation_date - ReservationInfo::CANCEL_WINDOW_DAYS.days).to_s,
        timestamp: Time.current.iso8601
      }, status: :unprocessable_entity
    end
    
    ActiveRecord::Base.transaction do
      reservation.cancel_reservation!
      refund_result = RefundService.new(reservation).process_refund
      
      unless refund_result[:success]
        Rails.logger.error "Refund failed for reservation #{reservation.id}: #{refund_result[:error]}"
      end
      
      render json: {
        message: "Reservation cancelled successfully",
        reservation_id: reservation.id,
        cancellation_token: reservation.cancellation_token,
        refund_processed: refund_result[:success],
        refund_status: refund_result[:status]
      }, status: :ok
    end
    
  rescue => e
    Rails.logger.error "Cancellation failed: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { 
      error: "Cancellation failed. Please try again or contact support.",
      timestamp: Time.current.iso8601 
    }, status: :internal_server_error
  end
  
  private
  
  def set_reservation_info
    @reservation_info = ReservationInfo.find(params[:id])
  end
  
  def fetch_reservation_infos
    if params[:booking_date_id]
      ReservationInfo.where(booking_date_id: params[:booking_date_id])
    elsif params[:reservation_date]
      booking_date = BookingDate.find_by(date: params[:reservation_date])
      booking_date ? booking_date.reservation_infos : ReservationInfo.none
    else
      ReservationInfo.all
    end
  end
  
  def extract_cancellation_token
    token_param = params[:cancellation_token] || params.dig(:reservation_info, :cancellation_token)
    token_param = token_param.first if token_param.is_a?(Array)
    token_param.to_s.strip.presence
  end
  
  def render_token_missing_error
    render json: { 
      error: "Cancellation token is required",
      timestamp: Time.current.iso8601 
    }, status: :bad_request
  end
  
  def render_reservation_not_found_error
    render json: { 
      error: "Reservation not found with provided token",
      timestamp: Time.current.iso8601 
    }, status: :not_found
  end
  
  def reservation_info_params
    params.require(:reservation_info).permit(
      :first_name, :last_name, :email, :mobile_number, :reservation_date, 
      :meal_period, :number_of_guest, :customer_notes, :first_course, 
      :second_course, :third_course, :fourth_course, :fifth_course, 
      :sixth_course, :seventh_course, :eighth_course, :ninth_course, 
      :downpayment, :cancellation_token
    )
  end
end
