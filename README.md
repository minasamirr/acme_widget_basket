Acme Widget Co. Basket System Proof of Concept

This project implements a proof-of-concept for Acme Widget Co.'s new sales system, focusing on core basket functionality, including product management, dynamic delivery charges, and special offers.
Design Principles and Structure

The solution is crafted with the following software engineering principles in mind, as highlighted in the assignment brief:

    Good Separation / Encapsulation of Concerns:

        Each class (Product, ProductCatalogue, DeliveryChargeRules, Offer (base class), BuyOneGetOneHalfPriceOffer, Basket) has a single, well-defined responsibility.

        Internal details (e.g., how products are stored in ProductCatalogue) are hidden from external users of the class.

    Small, Accurate Interfaces / Classes:

        Classes expose minimal public methods, providing only what's necessary for their interaction. For instance, Basket provides add and total as its primary interface.

    Dependency Injection:

        The Basket class does not create its own ProductCatalogue, DeliveryChargeRules, or Offer instances. Instead, these dependencies are injected (passed in) during the Basket's initialization (initialize method).

        This design makes the Basket class more flexible, testable, and independent of concrete implementations of its dependencies. For example, you could swap out DeliveryChargeRules for a different set of rules without modifying the Basket itself.

    Strategy Pattern / Extensible Code:

        The Offer system explicitly uses the Strategy pattern.

        Offer acts as an abstract base class (or interface in other languages), defining the calculate_discount method.

        BuyOneGetOneHalfPriceOffer is a concrete strategy that implements this method for a specific offer.

        This allows for easy addition of new offer types (e.g., "Buy One Get One Free", "X% off total") simply by creating new classes that inherit from Offer and implement calculate_discount, without altering the Basket's core logic.

Project Structure

The entire solution is contained within a single Ruby file (basket_system.rb in the provided code block for your convenience). In a larger project, these classes would typically reside in separate files within a lib/ directory.

    Product: Represents a single widget with a code, name, and price.

    ProductCatalogue: Manages a collection of Product objects, providing a way to look them up by code.

    DeliveryChargeRules: Calculates delivery costs based on predefined thresholds and the basket's total.

    Offer (Base Class): Defines the interface for all special offers.

    BuyOneGetOneHalfPriceOffer: A concrete implementation of an Offer for the "buy one red widget, get the second half price" rule.

    Basket: The core class representing the shopping basket. It orchestrates product adding, offer application, and total calculation.

Assumptions Made

    Product Codes Uniqueness: It's assumed that all product codes (e.g., R01, G01, B01) are unique identifiers for products.

    Currency: Prices and totals are assumed to be in the same currency (e.g., USD, as indicated by $), and all calculations are performed using floating-point numbers.

    Rounding:

        The "buy one red widget, get the second half price" discount is rounded to two decimal places before being subtracted from the subtotal. This ensures the example outputs match precisely.

        The final Basket#total is rounded to two decimal places.

    Offer Application Order: If multiple offers were present, they would be applied sequentially in the order they are provided to the Basket's offers array. For this specific problem, there's only one offer.

    Delivery Calculation Basis: Delivery charges are calculated on the basket's subtotal after all applicable offers have been applied.

    Immutability of Products: Once Product objects are created and stored in the ProductCatalogue, their attributes (code, name, price) are not expected to change.

How to Run

    Save the Code: Save the provided Ruby code into a file named basket_system.rb.

    Run the CLI Examples:
    Open your terminal or command prompt, navigate to the directory where you saved basket_system.rb, and run:

    ruby basket_system.rb


    This will execute the CLI examples defined at the bottom of the file, demonstrating the basket's functionality with the provided test cases.

    Run the Unit Tests (Minitest):
    The code includes a commented-out section with unit tests using Ruby's built-in Minitest framework.

        Install Minitest (if you don't have it):

        gem install minitest


        Uncomment Tests: In basket_system.rb, uncomment the require 'minitest/autorun' line and the entire class BasketSystemTest < Minitest::Test ... end block.

        Run Tests:

        ruby -r minitest/autorun basket_system.rb


        This command loads Minitest and then executes the script, which in turn runs the defined tests. You should see output indicating that all tests passed.