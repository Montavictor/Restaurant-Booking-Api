class RemoveFeservationInfoFromApiV1Courses < ActiveRecord::Migration[7.2]
  def change
    remove_reference :api_v1_courses, :reservation_info, null: false, foreign_key: true
  end
end
