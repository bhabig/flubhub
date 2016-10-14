class Item < ActiveRecord::Base
  belongs_to :order

  @@cheeses = []
  @@buns = []
  @@extras = []
  @@meats = []

  def self.sorter
    self.all.each do |i|
      i.ingredients.split(", ").each do |ingredient|
        if ingredient.include?("bun")
          Item.buns << ingredient unless Item.buns.include?("#{ingredient}")
        elsif ingredient.include?("lb.")
          Item.meats << ingredient unless Item.meats.include?("#{ingredient}")
        elsif ingredient.include?("cheese")
          Item.cheeses << ingredient unless Item.cheeses.include?("#{ingredient}")
        else
          Item.extras << ingredient unless Item.extras.include?("#{ingredient}")
        end
      end
    end
  end

  def self.meats
    @@meats
  end

  def self.buns
    @@buns
  end

  def self.cheeses
    @@cheeses
  end

  def self.extras
    @@extras
  end

end
