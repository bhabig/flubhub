items_list = {
    "The Mayor" => {
      ingredients: "whole wheat bun, 1/2lb. angus beef, pickled onions, jalepenos, pepperjack cheese, chipotle aioli, paprika mayo",
      price: 8.99
    },
    "The Don" => {
      ingredients: "sprouted bun, 1/2lb. carribou, chickpea onions, arugala, amish cheese, pesto, smoked mayo",
      price: 10.99
    },
    "Mr. President" => {
      ingredients: "facoccia bun, 1/2lb. wild boar, spinach, olives, bacon, southwestern mustard, jalepeno mayo",
      price: 9.99
    }
  }



items_list.each do |name, figure_hash|
  p = Item.new
  p.name = name
  p.ingredients = figure_hash[:ingredients]
  p.price = figure_hash[:price]
  p.save
end

Item.all.map do |item|
  item.ingredients.map! do |ingredient|
    if ingredient.include?("bun")
      BUNS << ingredient.strip
    elsif ingredient.include?("lb.")
      MEATS << ingredient.strip
    elsif ingredients.include?("cheese")
      CHEESES << ingredient.strip
    else
      EXTRAS << ingredient.strip
    end
  end
end
