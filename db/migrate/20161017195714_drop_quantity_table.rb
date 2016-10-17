class DropQuantityTable < ActiveRecord::Migration
  def change
    drop_table :quantity
  end
end
