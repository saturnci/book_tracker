class CreateAuthors < ActiveRecord::Migration[8.0]
  def change
    create_table :authors do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.integer :birth_year, null: false

      t.timestamps
    end

    add_index :authors, %i(first_name last_name birth_year), unique: true
  end
end
