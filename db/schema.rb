# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_08_13_142502) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "api_v1_courses", force: :cascade do |t|
    t.string "name"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "api_v1_meal_items", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.bigint "api_v1_course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_v1_course_id"], name: "index_api_v1_meal_items_on_api_v1_course_id"
  end

  create_table "booking_dates", force: :cascade do |t|
    t.date "date"
    t.boolean "is_lunch_available"
    t.boolean "is_dinner_available"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti"
    t.datetime "exp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "reservation_infos", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "mobile_number"
    t.date "reservation_date"
    t.string "meal_period"
    t.integer "number_of_guest"
    t.string "customer_notes"
    t.string "status"
    t.string "cancellation_token"
    t.string "stripe_id"
    t.integer "price"
    t.integer "downpayment"
    t.integer "total"
    t.bigint "booking_date_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_course"
    t.string "second_course"
    t.string "third_course"
    t.string "fourth_course"
    t.string "fifth_course"
    t.string "sixth_course"
    t.string "seventh_course"
    t.string "eighth_course"
    t.string "ninth_course"
    t.index ["booking_date_id"], name: "index_reservation_infos_on_booking_date_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.boolean "is_admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "api_v1_meal_items", "api_v1_courses"
  add_foreign_key "reservation_infos", "booking_dates"
end
