class RenameApiV1CoursesAndMealItems < ActiveRecord::Migration[7.2]
  def change
    rename_table :api_v1_courses, :courses
    rename_table :api_v1_meal_items, :meal_items
  end
end
