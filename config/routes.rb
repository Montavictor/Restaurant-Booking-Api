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
      resources :booking_dates, only: [:index, :show, :create, :update, :destroy] 
      resources :reservation_infos, only: [:index, :show, :create, :update, :destroy]
      resources :courses
      resources :meal_items, only: [:index, :show, :update]
      resources :reservations, controller: 'reservation_infos'
        
    end
  end
end