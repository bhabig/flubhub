class AddAmountsColumnToQuantities < ActiveRecord::Migration
  def change
    add_column :quantities, :amount, :integer, default: 1
  end
end
