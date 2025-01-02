Feature: Use Version Giving Only The Major Version Number

	Background:
		Given the internet is reachable
		And an initialised environment

	Scenario: Use a grails version that is installed giving only major version
		Given the candidate "grails" version "1.3.0" is already installed and default
		And the candidate "grails" version "2.1.0" is already installed but not default
		And the system is bootstrapped
		When I enter "sdk use grails 2"
		Then I see "Using grails version 2.1.0 in this shell."
		Then the candidate "grails" version "2.1.0" should be in use

	Scenario: Fail to use a major version because there are multiple matching versions
		Given the candidate "grails" version "1.3.0" is already installed and default
		And the candidate "grails" version "2.1.0" is already installed but not default
		And the candidate "grails" version "2.3.0" is already installed but not default
		And the system is bootstrapped
		When I enter "sdk use grails 2"
		Then I see "Stop! Cannot decide which version to use."

	Scenario: Fail to use a major version because there is no matching version
		Given the candidate "grails" version "1.3.0" is already installed and default
		And the system is bootstrapped
		When I enter "sdk use grails 2"
		Then I see "Stop! No matching version found."
		