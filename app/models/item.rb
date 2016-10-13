class Item < ActiveRecord::Base
  belongs_to :order

  @@meats = []
  @@cheeses = []
  @@buns = []
  @@extras = []
end
