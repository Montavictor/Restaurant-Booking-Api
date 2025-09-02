# db/seeds.rb

ActiveRecord::Base.transaction do
  # Clean slate
  MealItem.destroy_all
  Course.destroy_all

  courses_with_items = {
    1 => {
      name: "Amuse-Bouche",
      items: [
        ["Truffle arancini", "Crispy risotto bites infused with truffle."],
        ["Smoked salmon tartlet", "Delicate tartlet topped with smoked salmon."],
        ["Mini caprese skewer", "Fresh mozzarella, basil, and tomato on a skewer."]
      ]
    },
    2 => {
      name: "Soup",
      items: [
        ["Roasted tomato basil soup", "Velvety tomato soup with a basil finish."],
        ["French onion soup", "Rich broth topped with caramelized onions and cheese."],
        ["Miso soup", "Classic Japanese broth with tofu and seaweed."]
      ]
    },
    3 => {
      name: "Appetizer",
      items: [
        ["Tuna tartare", "Fresh tuna cubes with citrus and herbs."],
        ["Burrata with heirloom tomatoes", "Creamy burrata over sweet tomatoes."],
        ["Foie gras pâté on brioche", "Luxurious pâté on toasted brioche."]
      ]
    },
    4 => {
      name: "Salad",
      items: [
        ["Caesar salad with parmesan crisps", "Classic Caesar with a crunchy twist."],
        ["Arugula and pear salad", "Peppery greens balanced with sweet pear."],
        ["Beet and goat cheese salad", "Earthy beets with tangy goat cheese."]
      ]
    },
    5 => {
      name: "Fish Course",
      items: [
        ["Seared scallops with lemon butter", "Tender scallops in zesty butter sauce."],
        ["Grilled salmon with dill sauce", "Juicy salmon with herbed dill cream."],
        ["Miso-glazed cod", "Flaky cod finished with a sweet-savory glaze."]
      ]
    },
    6 => {
      name: "Pasta/Risotto",
      items: [
        ["Wild mushroom risotto", "Creamy risotto with earthy mushrooms."],
        ["Lobster ravioli", "Handmade pasta filled with tender lobster."],
        ["Pesto tagliatelle", "Fresh pasta tossed in basil pesto."]
      ]
    },
    7 => {
      name: "Main (Meat/Poultry)",
      items: [
        ["Beef tenderloin with red wine reduction", "Succulent beef in a rich sauce."],
        ["Roasted duck breast with orange glaze", "Crispy duck paired with citrus."],
        ["Herb-crusted lamb chops", "Juicy lamb with a fragrant herb crust."]
      ]
    },
    8 => {
      name: "Cheese Course",
      items: [
        ["Brie with fig jam", "Creamy brie complemented by sweet fig."],
        ["Blue cheese with honey and walnuts", "Bold cheese balanced with honeyed crunch."],
        ["Manchego with quince paste", "Spanish classic pairing of cheese and quince."]
      ]
    },
    9 => {
      name: "Dessert",
      items: [
        ["Chocolate lava cake", "Warm cake with a molten chocolate center."],
        ["Crème brûlée", "Silky custard topped with caramelized sugar."],
        ["Mango sorbet", "Refreshing sorbet with tropical mango flavor."]
      ]
    }
  }

  courses_with_items.each do |position, data|
    course = Course.create!(
      name: data[:name],
      position: position
    )

    data[:items].each do |name, description|
      course.meal_items.create!(
        name: name,
        description: description
      )
    end
  end

  puts "✅ Seeded #{Course.count} courses and #{MealItem.count} meal items."
end
