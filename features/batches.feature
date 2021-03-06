Feature: CRUD for batches

  Scenario: convert a whitespace delimited list of IEIDs to a batch
    Given the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    And I goto "/batches"
    And I fill in "name" with "foo"
    And I fill in "packages" with: 
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    When I press "Submit"
    Then I should be redirected
    And I click on "foo"
    And I should have a batch containing
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|

  Scenario: add to an existing batch
    Given the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
      |E00000000_000004|
    Given batch "foo" with the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    And I goto "/batches"
    And I click on "foo"
    And I fill in "packages" with:
      |E00000000_000001|
      |E00000000_000003|
      |E00000000_000004|
    When I press "Submit"
    Then I should be redirected
    And I should have a batch containing
      |E00000000_000001|
      |E00000000_000003|
      |E00000000_000004|
    And I should have a batch not containing
      |E00000000_000002|

  Scenario: delete a batch
    Given the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    Given batch "foo" with the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    And I goto "/batches"
    And I press "Delete"
    Then I should be redirected
    And I should not have batch "foo"

  Scenario: create requests for batch from batches page 
    Given the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    Given batch "foo" with the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    And I goto "/batches"
    And I fill in "note" with "my request note"
    And I press "Disseminate"
    Then I should be redirected
    And I should have a disseminate request for the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|

  Scenario Outline: create requests for batch from single batch page
    Given the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    Given batch "foo" with the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    And I goto "/batches/foo"
    And I fill in "note" with "my request note"
    And I select type "<request_type>"
    And I press "Submit Request"
    Then I should be redirected
    And I should have a <request_type> request for the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
      Examples:
        |request_type|
        |disseminate|
        |withdraw|
        #|peek|
        
  Scenario: create requests without note on batch should return 400
    Given the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    Given batch "foo" with the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    And I goto "/batches"
    And I press "Disseminate"
    Then the response code should be 400

  Scenario: don't create requests for rejected or withdrawn packages 
    Given the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    And the following rejected packages:
      |E00000000_000004|
    And the following withdrawn packages:
      |E00000000_000005|
    Given batch "foo" with the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
      |E00000000_000004|
      |E00000000_000005|
    And I goto "/batches"
    And I fill in "note" with "my request note"
    And I press "Disseminate"
    Then I should be redirected
    And I should have a disseminate request for the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    And I should not have a disseminate request for the following packages:
      |E00000000_000004|
      |E00000000_000005|

  Scenario: packages should be able to be in more than one batch
    Given the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    And I goto "/batches"
    And I fill in "name" with "foo"
    And I fill in "packages" with: 
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    When I press "Submit"
    And I goto "/batches"
    And I fill in "name" with "bar"
    And I fill in "packages" with: 
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    And I press "Submit"
    Then I goto "/batches"
    And I click on "foo"
    And I should have a batch containing
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    Then I goto "/batches"
    And I click on "bar"
    And I should have a batch containing
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|

	 Scenario: create batch from packages page
	    Given an archived package
	    When I goto "/packages"
	    And I fill in "name" with "mybatch"
	    And I press "Save as Batch"
	    And I should be redirected
	    And I click on "mybatch"
	    Then the batch should contain the last package ingested





