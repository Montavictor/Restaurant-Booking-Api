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
    let!(:reservation1) { create(:reservation_info, booking_date: booking_date) }
    let!(:reservation2) { create(:reservation_info, booking_date: booking_date) }
    let(:other_booking_date) { create(:booking_date, date: 1.week.from_now) }
    let!(:other_reservation) { create(:reservation_info, booking_date: other_booking_date) }

    context "when fetching all reservations" do
      it "returns all reservations with correct structure" do
        get api_v1_reservations_path
        
        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data.length).to eq(3)
        
        # Verify response structure
        first_reservation = response_data.first
        expect(first_reservation).to include("id", "first_name", "last_name", "email")
        expect(first_reservation).to include("booking_date")
        expect(first_reservation["booking_date"]).to include("id", "date", "is_lunch_available", "is_dinner_available")
        expect(first_reservation).not_to include("created_at", "updated_at")
      end
    end

    context "when filtering by booking_date_id" do
      it "returns only reservations for specified booking date" do
        get api_v1_reservations_path, params: { booking_date_id: booking_date.id }
        
        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data.length).to eq(2)
        response_data.each do |reservation|
          expect(reservation["booking_date"]["id"]).to eq(booking_date.id)
        end
      end
    end

    context "when filtering by reservation_date" do
      it "returns reservations for specified date" do
        get api_v1_reservations_path, params: { reservation_date: booking_date.date }
        
        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data.length).to eq(2)
      end

      it "returns empty array when no reservations exist for date" do
        non_existent_date = 2.years.from_now.to_date
        get api_v1_reservations_path, params: { reservation_date: non_existent_date }
        
        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data).to be_empty
      end
    end
  end

  describe "GET /show" do
    it "returns the specific reservation_info with correct structure" do
      get api_v1_reservation_path(reservation_info)
      
      expect(response).to have_http_status(:ok)
      response_data = JSON.parse(response.body)
      expect(response_data["id"]).to eq(reservation_info.id)
      expect(response_data).to include("booking_date")
      expect(response_data).not_to include("created_at", "updated_at")
    end

    it "returns 404 when reservation doesn't exist" do
      expect {
        get api_v1_reservation_path(id: 99999)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "POST /create" do
    let(:payment_service) { instance_double(PaymentService) }
    
    before do
      allow(PaymentService).to receive(:new).with(valid_reservation_params).and_return(payment_service)
    end
    
    context "when payment service succeeds" do
      let(:success_result) do
        {
          success: true,
          client_secret: "pi_test_client_secret",
          amount_info: { total: 2880000, downpayment: 1000000 }
        }
      end

      it "returns payment details with correct structure" do
        allow(payment_service).to receive(:create_payment_intent).and_return(success_result)

        post api_v1_reservations_path, params: { reservation_info: valid_reservation_params }

        expect(response).to have_http_status(:created)
        response_data = JSON.parse(response.body)
        expect(response_data["stripe_client_secret"]).to eq("pi_test_client_secret")
        expect(response_data["amount_info"]).to eq({ "total" => 2880000, "downpayment" => 1000000 })
      end

      it "calls PaymentService with correct parameters" do
        allow(payment_service).to receive(:create_payment_intent).and_return(success_result)
        
        post api_v1_reservations_path, params: { reservation_info: valid_reservation_params }
        
        expect(PaymentService).to have_received(:new).with(valid_reservation_params)
        expect(payment_service).to have_received(:create_payment_intent)
      end
    end

    context "when payment service fails" do
      let(:error_result) do
        { success: false, error: "Invalid payment details" }
      end

      it "returns error response with timestamp" do
        allow(payment_service).to receive(:create_payment_intent).and_return(error_result)
        freeze_time = Time.current
        
        travel_to freeze_time do
          post api_v1_reservations_path, params: { reservation_info: valid_reservation_params }
        end

        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body)
        expect(response_data["error"]).to eq("Invalid payment details")
        expect(response_data["timestamp"]).to eq(freeze_time.iso8601)
      end
    end

    context "with invalid parameters" do
      it "handles missing required parameters" do
        invalid_params = valid_reservation_params.except(:first_name, :email)
        
        expect {
          post api_v1_reservations_path, params: { reservation_info: invalid_params }
        }.to raise_error(ActionController::ParameterMissing)
      end

      it "filters unpermitted parameters" do
        params_with_extra = valid_reservation_params.merge(admin_notes: "Should be filtered")
        allow(payment_service).to receive(:create_payment_intent).and_return({ success: true, client_secret: "test", amount_info: {} })
        
        post api_v1_reservations_path, params: { reservation_info: params_with_extra }
        
        expect(PaymentService).to have_received(:new).with(valid_reservation_params)
      end
    end
  end

  describe "POST /confirm" do
    let(:payment_service) { instance_double(PaymentService) }
    let(:payment_intent_id) { "pi_test_123" }

    before do
      allow(PaymentService).to receive(:new).with({}).and_return(payment_service)
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
        allow(payment_service).to receive(:confirm_payment).with(payment_intent_id).and_return(success_result)

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
        allow(payment_service).to receive(:confirm_payment).with(payment_intent_id).and_return(success_result)

        post confirm_api_v1_reservations_path, params: { payment_intent_id: payment_intent_id }

        expect(response).to have_http_status(:ok)
        response_data = JSON.parse(response.body)
        expect(response_data["message"]).to eq("Reservation already exists")
        expect(response_data["reservation_id"]).to be_nil
      end
    end

    context "when confirmation fails" do
      let(:failure_result) do
        {
          success: false,
          error: "Payment intent not found",
          details: "The payment intent pi_test_123 could not be found"
        }
      end

      it "returns error response" do
        allow(payment_service).to receive(:confirm_payment).with(payment_intent_id).and_return(failure_result)
        freeze_time = Time.current

        travel_to freeze_time do
          post confirm_api_v1_reservations_path, params: { payment_intent_id: payment_intent_id }
        end

        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body)
        expect(response_data["error"]).to eq("Payment intent not found")
        expect(response_data["details"]).to eq("The payment intent pi_test_123 could not be found")
        expect(response_data["timestamp"]).to eq(freeze_time.iso8601)
      end
    end

    context "when payment_intent_id is missing" do
      it "handles missing payment_intent_id parameter" do
        post confirm_api_v1_reservations_path, params: {}
        
        # This should be handled by the PaymentService, but let's ensure it doesn't break
        expect(payment_service).to have_received(:confirm_payment).with(nil)
      end
    end
  end

  describe "POST /cancel" do 
    let(:cancellation_token) { "test_token_123" }
    let(:reservation) { create(:reservation_info, cancellation_token: cancellation_token, status: "confirmed", reservation_date: 1.week.from_now) }
    let(:refund_service) { instance_double(RefundService) }

    before do
      allow(RefundService).to receive(:new).with(reservation).and_return(refund_service)
    end

    context "when cancellation succeeds" do
      before do
        allow(reservation).to receive(:cancelled?).and_return(false)
        allow(reservation).to receive(:can_be_cancelled?).and_return(true)
        allow(reservation).to receive(:cancel_reservation!)
        allow(ReservationInfo).to receive(:find_by).with(cancellation_token: cancellation_token).and_return(reservation)
      end

      it "cancels reservation and processes refund successfully" do
        allow(refund_service).to receive(:process_refund).and_return({
          success: true,
          status: "succeeded"
        })

        post cancel_api_v1_reservations_path, params: { cancellation_token: cancellation_token }

        expect(response).to have_http_status(:ok)
        response_data = JSON.parse(response.body)
        expect(response_data["message"]).to eq("Reservation cancelled successfully")
        expect(response_data["reservation_id"]).to eq(reservation.id)
        expect(response_data["cancellation_token"]).to eq(cancellation_token)
        expect(response_data["refund_processed"]).to be true
        expect(response_data["refund_status"]).to eq("succeeded")
      end

      it "logs error when refund fails but still cancels reservation" do
        allow(refund_service).to receive(:process_refund).and_return({
          success: false,
          error: "Refund processing failed",
          status: "failed"
        })
        allow(Rails.logger).to receive(:error)

        post cancel_api_v1_reservations_path, params: { cancellation_token: cancellation_token }

        expect(response).to have_http_status(:ok)
        response_data = JSON.parse(response.body)
        expect(response_data["refund_processed"]).to be false
        expect(response_data["refund_status"]).to eq("failed")
        expect(Rails.logger).to have_received(:error).with(/Refund failed for reservation/)
      end
    end

    context "when reservation is already cancelled" do
      let(:cancelled_reservation) do 
        create(:reservation_info, 
               cancellation_token: cancellation_token, 
               status: "cancelled",
               updated_at: 1.hour.ago)
      end

      it "returns already cancelled message" do
        allow(ReservationInfo).to receive(:find_by).with(cancellation_token: cancellation_token).and_return(cancelled_reservation)
        allow(cancelled_reservation).to receive(:cancelled?).and_return(true)
        freeze_time = cancelled_reservation.updated_at

        post cancel_api_v1_reservations_path, params: { cancellation_token: cancellation_token }

        expect(response).to have_http_status(:ok)
        response_data = JSON.parse(response.body)
        expect(response_data["message"]).to eq("Reservation already cancelled")
        expect(response_data["reservation_id"]).to eq(cancelled_reservation.id)
        expect(response_data["cancelled_at"]).to eq(freeze_time.iso8601)
      end
    end
    
    context "when reservation cannot be cancelled (within cancellation window)" do
      let(:recent_reservation) do
        create(:reservation_info, 
               cancellation_token: cancellation_token, 
               reservation_date: 1.day.from_now,
               status: "confirmed")
      end

      before do
        stub_const("ReservationInfo::CANCEL_WINDOW_DAYS", 3)
      end

      it "returns unprocessable entity error with details" do
        allow(ReservationInfo).to receive(:find_by).with(cancellation_token: cancellation_token).and_return(recent_reservation)
        allow(recent_reservation).to receive(:cancelled?).and_return(false)
        allow(recent_reservation).to receive(:can_be_cancelled?).and_return(false)
        freeze_time = Time.current
        expected_last_date = (recent_reservation.reservation_date - 3.days).to_s

        travel_to freeze_time do
          post cancel_api_v1_reservations_path, params: { cancellation_token: cancellation_token }
        end

        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body)
        expect(response_data["error"]).to include("Reservation cannot be cancelled within 3 days")
        expect(response_data["last_cancellation_date"]).to eq(expected_last_date)
        expect(response_data["timestamp"]).to eq(freeze_time.iso8601)
      end
    end

    context "when cancellation token is missing" do
      it "returns bad request when token is nil" do
        freeze_time = Time.current

        travel_to freeze_time do
          post cancel_api_v1_reservations_path, params: {}
        end

        expect(response).to have_http_status(:bad_request)
        response_data = JSON.parse(response.body)
        expect(response_data["error"]).to eq("Cancellation token is required")
        expect(response_data["timestamp"]).to eq(freeze_time.iso8601)
      end

      it "returns bad request when token is empty string" do
        post cancel_api_v1_reservations_path, params: { cancellation_token: "" }

        expect(response).to have_http_status(:bad_request)
      end

      it "returns bad request when token is whitespace only" do
        post cancel_api_v1_reservations_path, params: { cancellation_token: "   " }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when reservation is not found" do
      it "returns not found error" do
        allow(ReservationInfo).to receive(:find_by).with(cancellation_token: "nonexistent_token").and_return(nil)
        freeze_time = Time.current

        travel_to freeze_time do
          post cancel_api_v1_reservations_path, params: { cancellation_token: "nonexistent_token" }
        end

        expect(response).to have_http_status(:not_found)
        response_data = JSON.parse(response.body)
        expect(response_data["error"]).to eq("Reservation not found with provided token")
        expect(response_data["timestamp"]).to eq(freeze_time.iso8601)
      end
    end

    context "when unexpected error occurs" do
      it "handles database errors gracefully" do
        allow(ReservationInfo).to receive(:find_by).and_raise(ActiveRecord::StatementInvalid.new("Database error"))
        allow(Rails.logger).to receive(:error)
        freeze_time = Time.current

        travel_to freeze_time do
          post cancel_api_v1_reservations_path, params: { cancellation_token: cancellation_token }
        end

        expect(response).to have_http_status(:internal_server_error)
        response_data = JSON.parse(response.body)
        expect(response_data["error"]).to eq("Cancellation failed. Please try again or contact support.")
        expect(response_data["timestamp"]).to eq(freeze_time.iso8601)
        expect(Rails.logger).to have_received(:error).with(/Cancellation failed: Database error/)
      end
    end

    context "with different token parameter formats" do
      let(:token_in_nested_param) { "nested_token_123" }
      let(:reservation_with_nested_token) { create(:reservation_info, cancellation_token: token_in_nested_param, status: "confirmed") }

      it "extracts token from nested reservation_info params" do
        allow(ReservationInfo).to receive(:find_by).with(cancellation_token: token_in_nested_param).and_return(reservation_with_nested_token)
        allow(reservation_with_nested_token).to receive(:cancelled?).and_return(true)

        post cancel_api_v1_reservations_path, params: { 
          reservation_info: { cancellation_token: token_in_nested_param } 
        }

        expect(response).to have_http_status(:ok)
      end

      it "handles token as array (edge case)" do
        allow(ReservationInfo).to receive(:find_by).with(cancellation_token: cancellation_token).and_return(reservation)
        allow(reservation).to receive(:cancelled?).and_return(true)

        # Simulate array parameter (can happen with certain form submissions)
        post cancel_api_v1_reservations_path, params: { 
          cancellation_token: [cancellation_token, ""] 
        }

        expect(response).to have_http_status(:ok)
      end
    end
  end
end