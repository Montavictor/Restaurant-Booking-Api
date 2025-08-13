class CreateApiV1Courses < ActiveRecord::Migration[7.2]
  def change
    create_table :api_v1_courses do |t|
      t.string :name
      t.integer :position
      t.references :reservation_info, null: false, foreign_key: true

      t.timestamps
    end
  end
end
