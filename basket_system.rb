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