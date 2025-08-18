Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
Stripe.log_level = Rails.env.production? ? Stripe::LEVEL_ERROR : Stripe::LEVEL_INFO
