class ChangeAmountColumnFromQuantities < ActiveRecord::Migration
  def change
    change_column :quantities, :amount, :integer, default: 1
  end
end
