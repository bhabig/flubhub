class DropAmountsColumnQuantities < ActiveRecord::Migration
  def change
    remove_column :quantities, :amounts, :integer
  end
end
