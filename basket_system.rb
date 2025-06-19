# frozen_string_literal: true

# This file contains the core logic for the Acme Widget Co. Basket system.
# It includes classes for Products, ProductCatalogue, DeliveryChargeRules,
# a base Offer class, a concrete BuyOneGetOneHalfPriceOffer, and the main Basket class.

# Defines a single product with its unique code, descriptive name, and price.
class Product
  attr_reader :code, :name, :price

  # Initializes a new Product instance.
  #
  # @param code [String] The unique identifier for the product (e.g., 'R01').
  # @param name [String] A human-readable name for the product (e.g., 'Red Widget').
  # @param price [Float] The monetary price of the product.
  def initialize(code:, name:, price:)
    @code = code
    @name = name
    @price = price
  end

  # Provides a string representation of the product for display or debugging.
  #
  # @return [String] A formatted string showing the product's name, code, and price.
  def to_s
    "#{name} (#{code}) - $#{format('%.2f', price)}"
  end
end

# Manages and provides access to the collection of all available products.
# This acts as a central registry for products, allowing the Basket to retrieve
# product details by their code.
class ProductCatalogue
  # @return [Hash<String, Product>] A hash mapping product codes to their respective Product objects.
  attr_reader :products_by_code

  # Initializes the ProductCatalogue with an array of Product objects.
  #
  # @param products [Array<Product>] An array containing all Product instances available for sale.
  def initialize(products)
    # Convert the array of products into a hash for efficient lookup by product code.
    @products_by_code = products.map { |p| [p.code, p] }.to_h
  end

  # Retrieves a Product object based on its unique product code.
  #
  # @param code [String] The product code to search for.
  # @return [Product, nil] The Product object if found, otherwise `nil`.
  def find_product(code)
    @products_by_code[code]
  end
end

# Encapsulates the logic for calculating delivery charges based on the basket's total value.
# The rules are defined by thresholds and associated costs.
class DeliveryChargeRules
  # Initializes DeliveryChargeRules with a set of predefined rules.
  # The rules should be provided as an array of hashes, where each hash
  # has a `:threshold` (the minimum total for this rule to apply) and `:cost`.
  # It's crucial that the rules are sorted in descending order of their threshold
  # to ensure the correct rule is matched (e.g., $90+ free delivery should be checked before $50+).
  #
  # @param rules [Array<Hash>] An array of rule hashes, e.g.,
  #   `[{ threshold: 90.0, cost: 0.0 }, { threshold: 50.0, cost: 2.95 }, { threshold: 0.0, cost: 4.95 }]`
  def initialize(rules)
    # Sort rules by threshold in descending order to apply the highest applicable threshold first.
    @rules = rules.sort_by { |rule| -rule[:threshold] }
  end

  # Calculates the delivery cost for a given basket total.
  #
  # @param total [Float] The current total value of the basket (after offers, before delivery).
  # @return [Float] The calculated delivery cost. Returns 0.0 if no rule matches (though
  #   a rule with threshold 0.0 should always be present as a fallback).
  def calculate(total)
    # Find the first rule whose threshold is met by the given total.
    rule = @rules.find { |r| total >= r[:threshold] }
    rule ? rule[:cost] : 0.0
  end
end

# An abstract base class (or interface) for all special offers.
# This class implements the Strategy pattern, defining the common interface
# that all concrete offer implementations must adhere to. This allows new offers
# to be added without modifying the core Basket logic.
class Offer
  # Calculates the discount amount provided by this specific offer for the
  # given items in the basket.
  # This method must be implemented by concrete subclasses.
  #
  # @param basket_items [Array<Product>] An array of Product objects currently in the basket.
  # @return [Float] The total monetary discount applied by this offer.
  # @raise [NotImplementedError] If a subclass does not implement this method.
  def calculate_discount(basket_items)
    raise NotImplementedError, "#{self.class} must implement #calculate_discount method."
  end

  # Provides a human-readable description of the offer.
  # This method can be overridden by concrete subclasses to provide specific details.
  #
  # @return [String] A general description of the offer.
  def description
    "Generic Offer"
  end
end

# Implements the "buy one red widget, get the second half price" special offer.
# This concrete offer strategy counts red widgets and calculates the discount accordingly.
class BuyOneGetOneHalfPriceOffer < Offer
  RED_WIDGET_CODE = 'R01'.freeze # Constant for the product code of a Red Widget.

  # Calculates the discount specifically for the "buy one red widget, get the second half price" offer.
  # For every two red widgets, one is half price. The discount is rounded to two decimal places.
  #
  # @param basket_items [Array<Product>] An array of Product objects currently in the basket.
  # @return [Float] The total discount from this offer, rounded to two decimal places.
  def calculate_discount(basket_items)
    # Filter out only the red widgets from the basket.
    red_widgets = basket_items.select { |item| item.code == RED_WIDGET_CODE }
    num_red_widgets = red_widgets.count

    # If there are fewer than 2 red widgets, no discount applies.
    return 0.0 if num_red_widgets < 2

    # Calculate how many red widgets qualify for half price (e.g., 2 widgets = 1 half price, 3 widgets = 1 half price).
    # Integer division correctly handles this (e.g., 3 / 2 = 1).
    num_half_price_widgets = num_red_widgets / 2

    # Get the price of a red widget. Assuming all R01 products have the same price.
    red_widget_price = red_widgets.first.price

    # Calculate the total discount. The discount for each half-price widget is its price divided by 2.
    # The discount is rounded to two decimal places to match the example outputs.
    total_discount = num_half_price_widgets * (red_widget_price / 2.0)

    # Round the final discount to two decimal places for financial accuracy matching the test examples.
    total_discount.round(2)
  end

  # Provides a specific description for this offer.
  #
  # @return [String] A description of the Buy One Get One Half Price offer.
  def description
    "Buy one Red Widget, get the second half price (R01)"
  end
end

# The main Basket class, simulating a customer's shopping cart.
# It aggregates products, applies discounts, and calculates delivery charges
# based on injected rules and offers.
class Basket
  # @return [Array<Product>] The current list of products added to the basket.
  attr_reader :items

  # Initializes a new Basket instance.
  # This uses Dependency Injection to provide the necessary components:
  # product catalogue, delivery rules, and a list of offers.
  #
  # @param product_catalogue [ProductCatalogue] An instance of ProductCatalogue to look up products.
  # @param delivery_charge_rules [DeliveryChargeRules] An instance of DeliveryChargeRules for calculating delivery.
  # @param offers [Array<Offer>] An array of Offer objects that should be applied to the basket.
  def initialize(product_catalogue:, delivery_charge_rules:, offers: [])
    @product_catalogue = product_catalogue
    @delivery_charge_rules = delivery_charge_rules
    @offers = offers
    @items = [] # Initialize an empty array to hold products added to the basket.
  end

  # Adds a product to the basket using its product code.
  # The product is looked up in the provided ProductCatalogue.
  #
  # @param product_code [String] The unique code of the product to add.
  # @raise [ArgumentError] If the product code does not exist in the catalogue.
  def add(product_code)
    product = @product_catalogue.find_product(product_code)
    unless product
      raise ArgumentError, "Product with code '#{product_code}' not found in catalogue."
    end
    @items << product # Add the found Product object to the basket's items.
  end

  # Calculates the total cost of all items in the basket, taking into account
  # any applied special offers and delivery charges.
  # The final total is rounded to two decimal places.
  #
  # @return [Float] The final calculated total cost of the basket.
  def total
    # 1. Calculate the raw sum of all item prices.
    subtotal = calculate_subtotal

    # 2. Calculate the total discount from all applicable offers.
    total_discount = calculate_total_discount

    # 3. Calculate the subtotal after applying discounts. This value is used for delivery cost calculation.
    post_offer_subtotal = subtotal - total_discount

    # 4. Calculate the delivery cost based on the post-offer subtotal.
    delivery_cost = @delivery_charge_rules.calculate(post_offer_subtotal)

    # 5. Calculate the final total cost.
    final_total = post_offer_subtotal + delivery_cost

    # 6. Round the final total to two decimal places to match standard currency representation.
    final_total.round(2)
  end

  private

  # Helper method to calculate the sum of prices of all items currently in the basket.
  # This is the gross subtotal before any offers are applied.
  #
  # @return [Float] The sum of all item prices.
  def calculate_subtotal
    @items.sum(&:price)
  end

  # Helper method to calculate the combined discount from all configured offers.
  # Offers are applied sequentially. If multiple offers affect the same item,
  # their discounts are simply summed up.
  #
  # @return [Float] The total discount from all offers.
  def calculate_total_discount
    @offers.sum { |offer| offer.calculate_discount(@items) }
  end
end

# --- Configuration Data ---
# These constants define the initial state for the system.
# In a larger application, these might come from a database or configuration files.

# Product data for the Acme Widget Co. catalogue.
PRODUCTS_DATA = [
  { code: 'R01', name: 'Red Widget', price: 32.95 },
  { code: 'G01', name: 'Green Widget', price: 24.95 },
  { code: 'B01', name: 'Blue Widget', price: 7.95 }
].freeze

# Delivery charge rules based on basket total.
# Ordered by threshold in descending order, as expected by DeliveryChargeRules.
DELIVERY_RULES_DATA = [
  { threshold: 90.0, cost: 0.0 }, # Orders $90 or more have free delivery
  { threshold: 50.0, cost: 2.95 }, # For orders under $90 (but >= $50), delivery costs $2.95
  { threshold: 0.0, cost: 4.95 } # Orders under $50 (but >= $0), cost $4.95
].freeze

# Instances of special offers to be applied.
# Currently, only one offer is defined. More offers could be added here.
OFFERS_DATA = [
  BuyOneGetOneHalfPriceOffer.new # Initialize the specific offer strategy.
].freeze

# --- Global Initialization (for convenience in CLI/Tests) ---

# Helper method to transform raw product data hashes into Product objects.
#
# @param data [Array<Hash>] An array of hashes, each representing product data.
# @return [Array<Product>] An array of initialized Product objects.
def create_products(data)
  data.map { |p| Product.new(code: p[:code], name: p[:name], price: p[:price]) }
end

# Initialize the ProductCatalogue with the defined products.
CATALOGUE = ProductCatalogue.new(create_products(PRODUCTS_DATA)).freeze

# Initialize the DeliveryChargeRules with the defined delivery thresholds and costs.
DELIVERY_RULES = DeliveryChargeRules.new(DELIVERY_RULES_DATA).freeze

# The array of instantiated Offer objects.
OFFERS = OFFERS_DATA.freeze

# --- Test Cases (Minitest Framework) ---
# To run these tests:
# 1. Ensure you have Minitest installed: `gem install minitest`
# 2. Uncomment the `require 'minitest/autorun'` line below.
# 3. Save this file (e.g., `basket_system.rb`).
# 4. Run from your terminal: `ruby -r minitest/autorun basket_system.rb`

=begin
require 'minitest/autorun'

# Test suite for the Basket system and its components.
class BasketSystemTest < Minitest::Test
  # `setup` method is called before each test method runs.
  # It initializes the common dependencies for tests.
  def setup
    @catalogue = CATALOGUE
    @delivery_rules = DELIVERY_RULES
    @offers = OFFERS
  end

  # Test basic functionality of ProductCatalogue.
  def test_product_catalogue
    assert_equal 'Red Widget', @catalogue.find_product('R01').name
    assert_equal 32.95, @catalogue.find_product('R01').price
    assert_nil @catalogue.find_product('XYZ'), 'Should return nil for non-existent product'
  end

  # Test delivery charge calculation for various totals.
  def test_delivery_charge_rules
    assert_equal 4.95, @delivery_rules.calculate(10.0), 'Total $10.00 should cost $4.95 delivery' # < $50
    assert_equal 4.95, @delivery_rules.calculate(49.99), 'Total $49.99 should cost $4.95 delivery'
    assert_equal 2.95, @delivery_rules.calculate(50.0), 'Total $50.00 should cost $2.95 delivery' # >= $50, < $90
    assert_equal 2.95, @delivery_rules.calculate(89.99), 'Total $89.99 should cost $2.95 delivery'
    assert_equal 0.0, @delivery_rules.calculate(90.0), 'Total $90.00 should cost $0.00 delivery' # >= $90
    assert_equal 0.0, @delivery_rules.calculate(150.0), 'Total $150.00 should cost $0.00 delivery'
  end

  # Test the specific "Buy One Get One Half Price" offer logic.
  def test_buy_one_get_one_half_price_offer
    offer = BuyOneGetOneHalfPriceOffer.new
    red_widget = @catalogue.find_product('R01')
    green_widget = @catalogue.find_product('G01')
    red_widget_half_price = (red_widget.price / 2.0).round(2)

    assert_equal 0.0, offer.calculate_discount([green_widget]), 'No R01s, no discount'
    assert_equal 0.0, offer.calculate_discount([red_widget]), 'One R01, no discount'
    assert_equal red_widget_half_price, offer.calculate_discount([red_widget, red_widget]), 'Two R01s, one half price'
    assert_equal red_widget_half_price, offer.calculate_discount([red_widget, red_widget, red_widget]), 'Three R01s, one half price'
    assert_equal red_widget_half_price * 2, offer.calculate_discount([red_widget, red_widget, red_widget, red_widget]), 'Four R01s, two half price'
    assert_equal red_widget_half_price, offer.calculate_discount([red_widget, green_widget, red_widget]), 'Mixed items with two R01s'
  end

  # Test the `Basket` initialization and `add` method.
  def test_basket_initialization_and_add_method
    basket = Basket.new(product_catalogue: @catalogue, delivery_charge_rules: @delivery_rules, offers: @offers)
    assert_empty basket.items, 'Basket should be empty on initialization'
    basket.add('R01')
    assert_equal 1, basket.items.count, 'Basket should have one item after adding R01'
    assert_equal 'R01', basket.items.first.code, 'Added item should be R01'
    assert_raises(ArgumentError, "Should raise error for non-existent product code") { basket.add('XYZ') }
  end

  # --- Example Basket Tests from the Problem Description ---
  # These tests directly verify the example outputs provided in the prompt.

  def test_example_basket_b01_g01
    basket = Basket.new(product_catalogue: @catalogue, delivery_charge_rules: @delivery_rules, offers: @offers)
    basket.add('B01')
    basket.add('G01')
    # B01 (7.95) + G01 (24.95) = 32.90. No offer. Delivery for 32.90 (< $50) = 4.95. Total = 32.90 + 4.95 = 37.85
    assert_equal 37.85, basket.total
  end

  def test_example_basket_r01_r01
    basket = Basket.new(product_catalogue: @catalogue, delivery_charge_rules: @delivery_rules, offers: @offers)
    basket.add('R01')
    basket.add('R01')
    # R01 (32.95) + R01 (32.95) = 65.90.
    # Offer: one R01 half price (32.95 / 2).round(2) = 16.48 discount.
    # Post-offer subtotal = 65.90 - 16.48 = 49.42.
    # Delivery for 49.42 (< $50) = 4.95.
    # Total = 49.42 + 4.95 = 54.37.
    assert_equal 54.37, basket.total
  end

  def test_example_basket_r01_g01
    basket = Basket.new(product_catalogue: @catalogue, delivery_charge_rules: @delivery_rules, offers: @offers)
    basket.add('R01')
    basket.add('G01')
    # R01 (32.95) + G01 (24.95) = 57.90. No offer (only one R01).
    # Delivery for 57.90 (>= $50 and < $90) = 2.95.
    # Total = 57.90 + 2.95 = 60.85.
    assert_equal 60.85, basket.total
  end

  def test_example_basket_b01_b01_r01_r01_r01
    basket = Basket.new(product_catalogue: @catalogue, delivery_charge_rules: @delivery_rules, offers: @offers)
    basket.add('B01')
    basket.add('B01')
    basket.add('R01')
    basket.add('R01')
    basket.add('R01')
    # B01 (7.95*2) + R01 (32.95*3) = 15.90 + 98.85 = 114.75.
    # Offer: Three R01s -> one R01 half price (16.48 discount).
    # Post-offer subtotal = 114.75 - 16.48 = 98.27.
    # Delivery for 98.27 (>= $90) = 0.00.
    # Total = 98.27 + 0.00 = 98.27.
    assert_equal 98.27, basket.total
  end
end
=end

# --- Command Line Interface (CLI) Example ---
# This section demonstrates how to use the Basket system from the command line.
# You can run this by executing `ruby basket_system.rb` in your terminal.

if __FILE__ == $PROGRAM_NAME
  puts "========================================"
  puts "Acme Widget Co. Basket System PoC"
  puts "========================================"
  puts "\nAvailable Products:"
  CATALOGUE.products_by_code.values.each do |product|
    puts "- #{product}"
  end
  puts "\nDelivery Rules:"
  DELIVERY_RULES_DATA.each do |rule|
    puts "- Orders over $#{format('%.2f', rule[:threshold])} cost $#{format('%.2f', rule[:cost])} delivery"
  end
  puts "\nSpecial Offers:"
  OFFERS.each do |offer|
    puts "- #{offer.description}"
  end
  puts "========================================"

  # Example 1: B01, G01
  puts "\n--- Basket 1: B01, G01 ---"
  basket1 = Basket.new(product_catalogue: CATALOGUE, delivery_charge_rules: DELIVERY_RULES, offers: OFFERS)
  basket1.add('B01')
  basket1.add('G01')
  puts "Items: #{basket1.items.map(&:code).join(', ')}"
  puts "Total: $#{format('%.2f', basket1.total)}" # Expected: $37.85

  # Example 2: R01, R01
  puts "\n--- Basket 2: R01, R01 ---"
  basket2 = Basket.new(product_catalogue: CATALOGUE, delivery_charge_rules: DELIVERY_RULES, offers: OFFERS)
  basket2.add('R01')
  basket2.add('R01')
  puts "Items: #{basket2.items.map(&:code).join(', ')}"
  puts "Total: $#{format('%.2f', basket2.total)}" # Expected: $54.37

  # Example 3: R01, G01
  puts "\n--- Basket 3: R01, G01 ---"
  basket3 = Basket.new(product_catalogue: CATALOGUE, delivery_charge_rules: DELIVERY_RULES, offers: OFFERS)
  basket3.add('R01')
  basket3.add('G01')
  puts "Items: #{basket3.items.map(&:code).join(', ')}"
  puts "Total: $#{format('%.2f', basket3.total)}" # Expected: $60.85

  # Example 4: B01, B01, R01, R01, R01
  puts "\n--- Basket 4: B01, B01, R01, R01, R01 ---"
  basket4 = Basket.new(product_catalogue: CATALOGUE, delivery_charge_rules: DELIVERY_RULES, offers: OFFERS)
  basket4.add('B01')
  basket4.add('B01')
  basket4.add('R01')
  basket4.add('R01')
  basket4.add('R01')
  puts "Items: #{basket4.items.map(&:code).join(', ')}"
  puts "Total: $#{format('%.2f', basket4.total)}" # Expected: $98.27

  puts "\n--- Adding an unknown product (will raise ArgumentError) ---"
  begin
    basket_error = Basket.new(product_catalogue: CATALOGUE, delivery_charge_rules: DELIVERY_RULES, offers: OFFERS)
    basket_error.add('XYZ')
  rescue ArgumentError => e
    puts "Error: #{e.message}"
  end
end
