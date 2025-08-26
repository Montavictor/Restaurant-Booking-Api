class RenameApiV1CourseIdToCourseIdInMealItems < ActiveRecord::Migration[7.2]
  def change
    rename_column :meal_items, :api_v1_course_id, :course_id
  end
end
