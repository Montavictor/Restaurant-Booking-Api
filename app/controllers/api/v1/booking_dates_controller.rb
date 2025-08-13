class Api::V1::BookingDatesController < ApplicationController
  before_action :set_booking_date, only: %i[ show update destroy ]

  # GET /booking_dates
  def index
    @booking_dates = BookingDate.all

    render json: @booking_dates
  end

  # GET /booking_dates/1
  def show
    render json: @booking_date
  end

  # POST /booking_dates
  def create
    @booking_date = BookingDate.new(booking_date_params)

    if @booking_date.save
      render json: @booking_date, status: :created, location: @booking_date
    else
      render json: @booking_date.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /booking_dates/1
  def update
    if @booking_date.update(booking_date_params)
      render json: @booking_date
    else
      render json: @booking_date.errors, status: :unprocessable_entity
    end
  end

  # DELETE /booking_dates/1
  def destroy
    @booking_date.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_booking_date
      @booking_date = BookingDate.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def booking_date_params
      params.require(:booking_date).permit(:date, :is_lunch_available, :is_dinner_available)
    end
end
