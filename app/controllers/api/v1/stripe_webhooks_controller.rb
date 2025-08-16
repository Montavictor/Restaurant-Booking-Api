class Api::V1::StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]

    begin
      event = Stripe::Webhook.construct_event(
        payload,
        sig_header,
        endpoint_secret
      )
    rescue JSON::ParserError => e
      return render json: { error: "Invalid payload" }, status: 400
    rescue Stripe::SignatureVerificationError => e
      return render json: { error: "Invalid signature" }, status: 400
    end

    case event.type
    when "payment_intent.succeeded"
      handle_payment_intent_succeeded(event.data.object)
    when "charge.refunded"
      handle_charge_refunded(event.data.object)
    end

    head :ok
  end

  private

  def handle_payment_intent_succeeded(payment_intent)
    return if ReservationInfo.exists?(stripe_id: payment_intent.id)
    reservation = persist_from_payment_intent(payment_intent)
    ReservationMailer.confirmation_email(reservation).deliver_now
  end

  def handle_charge_refunded(charge)
    reservation = ReservationInfo.find_by(stripe_id: charge.payment_intent)
    return unless reservation

    reservation.update!(status: "cancelled")

    # Release time slot
    booking_date = reservation.booking_date
    if reservation.meal_period == "lunch"
      booking_date.update!(is_lunch_available: true)
    elsif reservation.meal_period == "dinner"
      booking_date.update!(is_dinner_available: true)
    end

    ReservationMailer.cancellation_email(reservation).deliver_later
  end

  def persist_from_payment_intent(payment_intent)
    metadata = payment_intent.metadata

    attributes = {
      first_name: metadata["first_name"],
      last_name: metadata["last_name"],
      email: metadata["email"],
      mobile_number: metadata["mobile_number"],
      reservation_date: metadata["reservation_date"],
      meal_period: metadata["meal_period"],
      number_of_guest: metadata["number_of_guest"].to_i,
      customer_notes: metadata["customer_notes"],
      first_course: metadata["first_course"],
      second_course: metadata["second_course"],
      third_course: metadata["third_course"],
      fourth_course: metadata["fourth_course"],
      fifth_course: metadata["fifth_course"],
      sixth_course: metadata["sixth_course"],
      seventh_course: metadata["seventh_course"],
      eighth_course: metadata["eighth_course"],
      ninth_course: metadata["ninth_course"],
      stripe_id: payment_intent.id,
      status: "confirmed",
      cancellation_token: SecureRandom.hex(10)
    }.compact

    ActiveRecord::Base.transaction do
      booking_date = BookingDate.find_or_create_by!(date: attributes[:reservation_date])
      reservation = ReservationInfo.create!(attributes.merge(booking_date: booking_date))
      case reservation.meal_period.downcase
      when "lunch" then booking_date.update!(is_lunch_available: false)
      when "dinner" then booking_date.update!(is_dinner_available: false)
      end

      reservation
    end
  end
end
