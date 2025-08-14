# app/controllers/api/v1/stripe/webhooks_controller.rb
class Api::V1::Stripe::WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig     = request.env["HTTP_STRIPE_SIGNATURE"]
    secret  = ENV["STRIPE_WEBHOOK_SECRET"]

    event = Stripe::Webhook.construct_event(payload, sig, secret)

    case event["type"]
    when "payment_intent.succeeded"
      pi = event["data"]["object"]

      # Idempotent: skip if already created (by this webhook or /confirm)
      ReservationInfo.find_by(stripe_id: pi["id"]) || persist_from_pi!(pi)
    end

    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    render json: { error: e.message }, status: :bad_request
  end

  private

  # Reuse the same logic; you can extract to a service to DRY.
  def persist_from_pi!(pi)
    # Build a fake controller to reuse helpers, or inline the same logic here:
    md = pi["metadata"]

    attrs = {
      first_name:       md["first_name"],
      last_name:        md["last_name"],
      email:            md["email"],
      mobile_number:    md["mobile_number"],
      reservation_date: md["reservation_date"],
      meal_period:      md["meal_period"],
      number_of_guest:  md["number_of_guest"],
      customer_notes:   md["customer_notes"],
      first_course:     md["first_course"],
      second_course:    md["second_course"],
      third_course:     md["third_course"],
      fourth_course:    md["fourth_course"],
      fifth_course:     md["fifth_course"],
      sixth_course:     md["sixth_course"],
      seventh_course:   md["seventh_course"],
      eighth_course:    md["eighth_course"],
      ninth_course:     md["ninth_course"],
      status:           "confirmed",
      stripe_id:        pi["id"]
    }.compact

    ActiveRecord::Base.transaction do
      booking_date = BookingDate.find_or_create_by!(date: attrs[:reservation_date])
      reservation  = ReservationInfo.create!(attrs.merge(booking_date: booking_date))
      case reservation.meal_period.to_s.downcase
      when "lunch"  then booking_date.update!(is_lunch_available: false)
      when "dinner" then booking_date.update!(is_dinner_available: false)
      end
      reservation
    end
  end
end
