class DropAmountsColumnFromQuantities < ActiveRecord::Migration
  def change
    remove_column :quantities, :amounts, :integer, default: 1
  end
end
