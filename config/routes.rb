Rails.application.routes.draw do
  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

  namespace :api do
    namespace :v1, defaults: { format: :json } do
      devise_for :users,
                 path: "",
                 path_names: {
                   sign_in: "login",
                   sign_out: "logout",
                   registration: "signup"
                 },
                 controllers: {
                   registrations: "users/registrations",
                   sessions: "users/sessions"
                 }

      # other routes...

      # reservations
      resources :reservations, controller: "reservation_infos", only: [:index, :show, :create] do
        collection do
           post "confirm"
           post "cancel"
        end
      end

      # bookings
      resources :bookings, controller: "booking_dates" do
        collection do
          post :upsert
        end
      end

      # courses has_many: meal_items
      resources :courses do
        resources :meal_items
      end

      # paper trail
      namespace :versions do
        resources :courses do
          resources :versions, only: [:index] do
            post :revert, on: :member
          end
        end
      end

      # for stripe webhook
      post "stripe/webhook", to: "stripe_webhooks#create"
    end
  end
end
