require 'rails_helper'

RSpec.describe "Api::V1::ReservationInfos", type: :request do
  let(:booking_date) { create(:booking_date) }
  let(:reservation_info) { create(:reservation_info, booking_date: booking_date) }
  let(:valid_reservation_params) do
    {
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      mobile_number: "12345678901",
      reservation_date: booking_date.date,
      meal_period: "lunch",
      number_of_guest: 12,
      customer_notes: "No special requests",
      first_course: "Salad",
      second_course: "Steak",
      third_course: "Ice Cream",
      fourth_course: "Coffee",
      fifth_course: "Tea",
      sixth_course: "Water",
      seventh_course: "Bread",
      eighth_course: "Butter",
      ninth_course: "Cheese",
      downpayment: 15000,
      cancellation_token: SecureRandom.hex(16)
    }
  end
  
  describe "GET /index" do
    context "when fetching all reservations" do
      before do
        create(:reservation_info, booking_date: booking_date)
      end
      it "returns all reservations" do
        get api_v1_reservation_infos_path
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body).length).to eq(1)
      end
    end
  end

  describe "GET /show" do
    it "returns the specific reservation_info" do
      get api_v1_reservation_info_path(reservation_info)

      
      expect(response).to have_http_status(:ok)
      response_data = JSON.parse(response.body)
      expect(response_data["id"]).to eq(reservation_info.id)
    end
  end

  describe "POST /create" do
    let(:payment_service) { instance_double(PaymentService) }
    before do
      allow(PaymentService).to receive(:new).and_return(payment_service)
    end
    
    context "when payment service succeeds" do
      let(:success_result) do
        {
          success: true,
          client_secret: "pi_test_client_secret",
          amount_info: { total: 2880000, downpayment: 1000000}
        }
      end

      it "returns payment details" do
        allow(payment_service).to receive(:create_payment_intent).and_return(success_result)

        post api_v1_reservation_infos_path, params: { reservation_info: valid_reservation_params }


        expect(response).to have_http_status(:created)
        response_data = JSON.parse(response.body)
        expect(response_data["stripe_client_secret"]).to eq("pi_test_client_secret")
        expect(response_data["amount_info"]).to be_present
      end
    end
    context "when payment service fails" do
      let(:error_result) do
        { success: false, error: "Invalid payment details" }
      end

      it "returns error response" do
        allow(payment_service).to receive(:create_payment_intent).and_return(error_result)
        
        post api_v1_reservation_infos_path, params: { reservation_info: valid_reservation_params }
        
        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body)
        expect(response_data["error"]).to eq("Invalid payment details")
        expect(response_data["timestamp"]).to be_present
      end
    end
  end

  describe "POST /confirm" do
    let(:payment_service) { instance_double(PaymentService) }
    let(:payment_intent_id) { "pi_test_123" }

    before do
      allow(PaymentService).to receive(:new).and_return(payment_service)
    end

    context "when confirmation succeeds with new reservation" do
      let(:success_result) do
        {
          success: true,
          message: "Reservation confirmed successfully", 
          reservation_id: 123
        }
      end

      it "returns success response with created status" do
        allow(payment_service).to receive(:confirm_payment).and_return(success_result)

        post confirm_api_v1_reservations_path, params: { payment_intent_id: payment_intent_id }

        expect(response).to have_http_status(:created)
        response_data = JSON.parse(response.body)
        expect(response_data["message"]).to eq("Reservation confirmed successfully")
        expect(response_data["reservation_id"]).to eq(123)
      end
    end

    context "when confirmation succeeds with existing reservation" do
      let(:success_result) do
        {
          success: true,
          message: "Reservation already exists", 
          reservation_id: nil
        }
      end

      it "returns success response with ok status" do
        allow(payment_service).to receive(:confirm_payment).and_return(success_result)

        post confirm_api_v1_reservations_path, params: { payment_intent_id: payment_intent_id }

        expect(response).to have_http_status(:ok)
        response_data = JSON.parse(response.body)
        expect(response_data["message"]).to eq("Reservation already exists")
      end
    end
  end

  describe "POST /cancel" do 
    let(:cancellation_token) { "test_token_123" }
    let(:reservation) { create(:reservation_info, cancellation_token: cancellation_token, status:"confirmed") }
    let(:refund_service) { instance_double(RefundService) } 

    before do
      allow(RefundService).to receive(:new).and_return(refund_service)
    end

    context "when cancellation succeeds" do
      it "cancels reservation and processes refund" do
        allow(reservation).to receive(:cancelled?).and_return(false)
        allow(reservation).to receive(:can_be_cancelled?).and_return(true)
        allow(reservation).to receive(:cancel_reservation!)
        allow(ReservationInfo).to receive(:find_by).and_return(reservation)
        allow(refund_service).to receive(:process_refund).and_return({
          success: true,
          status: "succeeded"
        })

        post cancel_api_v1_reservations_path, params: { cancellation_token: cancellation_token }

        expect(response).to have_http_status(:ok)
        response_data = JSON.parse(response.body)
        expect(response_data["message"]).to eq("Reservation cancelled successfully")
        expect(response_data["reservation_id"]).to eq(reservation.id)
        expect(response_data["refund_processed"]).to be true
        expect(response_data["refund_status"]).to eq("succeeded")
      end
    end
    
    context "when reservation cannot be canncelled (within cancellationwindow)" do
      it "returns unprocessable entity error" do
        recent_reservation = build_stubbed(:reservation_info, 
        cancellation_token: cancellation_token, 
        reservation_date: 1.day.from_now
        )

        allow(recent_reservation).to receive(:cancelled?).and_return(false)
        allow(recent_reservation).to receive(:can_be_cancelled?).and_return(false)
        allow(ReservationInfo).to receive(:find_by).and_return(recent_reservation)
        stub_const("ReservationInfo::CANCEL_WINDOW_DAYS", 3)

        post cancel_api_v1_reservations_path, params: { cancellation_token: cancellation_token }

        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body)
        expect(response_data["error"]).to include("Reservation cannot be cancelled")
      end
    end
  end
end