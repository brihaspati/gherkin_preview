# language: en
Feature: Calculator
  As a user
  I want to add and subtract numbers
  So that I can do basic arithmetic

  Background:
    Given a calculator

  @fast
  Scenario: Add two numbers
    Given I have entered 50 into the calculator
    And I have entered 70 into the calculator
    When I press add
    Then the result should be 120 on the screen

  @smoke @critical
  Scenario Outline: Add <a> and <b>
    Given I have entered <a> into the calculator
    And I have entered <b> into the calculator
    When I press add
    Then the result should be <sum> on the screen

    Examples:
      | a | b  | sum |
      | 1 | 2  | 3   |
      | 10 | 20 | 30  |

  Scenario: Document a table and payload
    Given the following JSON payload:
      """json
      {"a": 1, "b": 2}
      """
    And a data table:
      | key | value |
      | foo | 1     |
      | bar | 2     |
    Then everything is parsed

  Rule: Subtractions preserve sign

    Scenario: Subtract smaller from larger
      Given I have entered 100 into the calculator
      And I have entered 30 into the calculator
      When I press subtract
      Then the result should be 70 on the screen

    Scenario Outline: Subtract <a> and <b>
      Given I have entered <a> into the calculator
      And I have entered <b> into the calculator
      When I press subtract
      Then the result should be <diff> on the screen

      Examples:
        | a  | b | diff |
        | 10 | 4 | 6    |