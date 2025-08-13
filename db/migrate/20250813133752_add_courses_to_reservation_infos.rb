class AddCoursesToReservationInfos < ActiveRecord::Migration[7.2]
  def change
    add_column :reservation_infos, :first_course, :string
    add_column :reservation_infos, :second_course, :string
    add_column :reservation_infos, :third_course, :string
    add_column :reservation_infos, :fourth_course, :string
    add_column :reservation_infos, :fifth_course, :string
    add_column :reservation_infos, :sixth_course, :string
    add_column :reservation_infos, :seventh_course, :string
    add_column :reservation_infos, :eighth_course, :string
    add_column :reservation_infos, :ninth_course, :string
  end
end
