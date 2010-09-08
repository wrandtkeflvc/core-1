Feature: ingest a package

  Scenario: ingest a package. After complete, look for aip record, storage record, and events
    Given a workspace
    And it has 1 idle wip
    And I goto "/workspace"
    When I choose "start"
    And I press "Update"
    And all running wips have finished
    Then the package is present in the aip store
    And the package is present in storage
    And there is an event for submit
    And there is an event for ingest started
    And there is an event for ingest finished

    
