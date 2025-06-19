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

# --- Configuration Data ---
# These constants define the initial state for the system.
# In a larger application, these might come from a database or configuration files.

# Product data for the Acme Widget Co. catalogue.
PRODUCTS_DATA = [
  { code: 'R01', name: 'Red Widget', price: 32.95 },
  { code: 'G01', name: 'Green Widget', price: 24.95 },
  { code: 'B01', name: 'Blue Widget', price: 7.95 }
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
  end

  # Test basic functionality of ProductCatalogue.
  def test_product_catalogue
    assert_equal 'Red Widget', @catalogue.find_product('R01').name
    assert_equal 32.95, @catalogue.find_product('R01').price
    assert_nil @catalogue.find_product('XYZ'), 'Should return nil for non-existent product'
  end
end
=end

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

# Add to Configuration Data:
DELIVERY_RULES_DATA = [
  { threshold: 90.0, cost: 0.0 }, # Orders $90 or more have free delivery
  { threshold: 50.0, cost: 2.95 }, # For orders under $90 (but >= $50), delivery costs $2.95
  { threshold: 0.0, cost: 4.95 } # Orders under $50 (but >= $0), cost $4.95
].freeze

# Add to Global Initialization:
DELIVERY_RULES = DeliveryChargeRules.new(DELIVERY_RULES_DATA).freeze

# Update Test Cases:
=begin
# ... (existing ProductCatalogue tests) ...

# Test suite for the Basket system and its components.
class BasketSystemTest < Minitest::Test
  def setup
    @catalogue = CATALOGUE
    @delivery_rules = DELIVERY_RULES # Add this line
  end

  # ... (existing ProductCatalogue tests) ...

  # Test delivery charge calculation for various totals.
  def test_delivery_charge_rules
    assert_equal 4.95, @delivery_rules.calculate(10.0), 'Total $10.00 should cost $4.95 delivery' # < $50
    assert_equal 4.95, @delivery_rules.calculate(49.99), 'Total $49.99 should cost $4.95 delivery'
    assert_equal 2.95, @delivery_rules.calculate(50.0), 'Total $50.00 should cost $2.95 delivery' # >= $50, < $90
    assert_equal 2.95, @delivery_rules.calculate(89.99), 'Total $89.99 should cost $2.95 delivery'
    assert_equal 0.0, @delivery_rules.calculate(90.0), 'Total $90.00 should cost $0.00 delivery' # >= $90
    assert_equal 0.0, @delivery_rules.calculate(150.0), 'Total $150.00 should cost $0.00 delivery'
  end
end
=end