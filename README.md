Acme Widget Co. Basket System Proof of Concept

Hey there! This project is my take on Acme Widget Co.'s new sales system, specifically focusing on how the shopping basket works. It covers managing products, figuring out delivery costs, and applying those cool special offers.
How I Approached the Design

I built this with a few key software engineering ideas in mind, just like you'd expect from a good team member. The goal was to make it easy to understand, flexible, and ready for future changes:

    Keeping Things Separate (Encapsulation):

        Each part of the system, like Product, ProductCatalogue, DeliveryChargeRules, and Basket, has its own clear job.

        I've kept the internal workings of each part hidden. For example, the Basket doesn't need to know how the ProductCatalogue stores its products, just that it can find them.

    Clean and Focused Classes:

        I aimed for small, precise classes. Each one has just the methods it needs to do its job, nothing extra. So, the Basket pretty much only cares about adding items and calculating the total.

    Dependency Injection (Passing Things In):

        Instead of letting the Basket create its own ProductCatalogue or DeliveryChargeRules, I "inject" these into the Basket when it's set up.

        This makes the Basket much more flexible. If we ever want to change how delivery rules work, we can just swap out the DeliveryChargeRules object without touching the Basket itself!

    Strategy Pattern (Making Offers Flexible):

        The way special offers work uses something called the Strategy pattern.

        I've got a basic Offer class that sets the stage, defining how any offer should calculate_discount.

        Then, specific offers, like BuyOneGetOneHalfPriceOffer, just follow that pattern.

        This is super handy because it means we can add brand new types of offers (like "buy one get one free" or "X% off") without having to mess with the core Basket logic. It just knows how to ask an Offer for its discount.

A Quick Look at the Project Structure

For this proof of concept, I've kept everything in one Ruby file (basket_system.rb). In a bigger, real-world project, you'd usually split these classes into individual files, probably in a lib/ directory, for better organization.

Here are the main components:

    Product: This defines what a widget is – its code, name, and price.

    ProductCatalogue: Our shop's master list of all available products, letting us find them quickly by their code.

    DeliveryChargeRules: Handles all the logic for calculating shipping costs based on the order total.

    Offer (Base Class): The blueprint for any special offer we might want to create.

    BuyOneGetOneHalfPriceOffer: The specific offer we have right now: "buy one red widget, get the second half price."

    Basket: This is the heart of it all – it's where customers add their items, and it figures out the final total after all discounts and delivery charges.

What I Assumed

Just so we're clear, here are a few things I assumed while building this:

    Unique Product Codes: I'm assuming that each product code (like R01, G01, B01) is unique and identifies a single type of product.

    Currency: All prices and totals are in the same currency (looking at the examples, it seems like USD, given the $), and I'm using standard floating-point numbers for calculations.

    Rounding:

        The "buy one red widget, get the second half price" discount gets rounded to two decimal places before it's taken off the subtotal. This helps us match the example totals exactly.

        The final total for the whole basket is also rounded to two decimal places.

    Offer Order: If we had multiple offers, they'd be applied in the order they're given to the Basket. For now, we only have one!

    Delivery Calculation: Delivery charges are worked out after any offers have been applied to the item total.

    Products Don't Change: Once a product is set up in the ProductCatalogue, I'm not expecting its code, name, or price to change.

How to Get It Running

It's super easy to get this up and running:

    Save the Code: Just save the Ruby code into a file. Let's call it basket_system.rb.

    Run the Examples (CLI):
    Open your terminal or command prompt, go to the folder where you saved basket_system.rb, and type:

    ruby basket_system.rb

    This will run through the examples I've included at the bottom of the file, showing how the basket calculates totals for different scenarios.

    Run the Tests (Minitest):
    I've also included some unit tests using Ruby's built-in Minitest framework. They're commented out, but you can quickly run them:

        First, install Minitest (if you don't have it):

        gem install minitest

        Then, uncomment the tests: In basket_system.rb, find the require 'minitest/autorun' line and the entire class BasketSystemTest < Minitest::Test ... end block, and remove the =begin and =end lines around them.

        Finally, run the tests:

        ruby -r minitest/autorun basket_system.rb

        You should see a nice message confirming all the tests passed!
