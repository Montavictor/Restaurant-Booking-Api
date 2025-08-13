class CreateApiV1MealItems < ActiveRecord::Migration[7.2]
  def change
    create_table :api_v1_meal_items do |t|
      t.string :name
      t.string :description
      t.references :api_v1_course, null: false, foreign_key: true

      t.timestamps
    end
  end
end
