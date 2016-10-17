class CreateQuantities < ActiveRecord::Migration
  def change
    create_table :quantities do |t|
      t.integer :item_id
      t.integer :order_id
      t.integer :amount
    end
  end
end
