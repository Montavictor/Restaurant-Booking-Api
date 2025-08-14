Rails.application.routes.draw do
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
      resources :booking_dates, only: [:index, :show, :create] 
      resources :reservation_infos, only: [:index, :show, :create]
      resources :courses
      resources :meal_items, only: [:index, :show, :update]
      resources :reservations, controller: 'reservation_infos', only: [:create] do
        collection do
           post 'confirm'
           post 'cancel'
        end
      end
      post "stripe/webhook", to: "stripe#webhook"
    end
  end
end