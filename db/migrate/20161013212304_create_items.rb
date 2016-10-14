class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :name
      t.text :ingredients
      t.float :price
      t.integer :order_id
    end
  end
end
