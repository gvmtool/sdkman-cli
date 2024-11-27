@review
Feature: Pinned version series

	Background:
		Given the internet is reachable
		And an initialised environment
		
	Scenario: A major series is pinned for the default vendor to continuously upgrade
		Given a machine with "Linux" installed
		And the system is bootstrapped
		And the default vendor is "AdoptOpenJDK" with label "adpt"
		And the following candidate versions are available for download
		| java      | 11.0.6   | 11     | AdoptOpenJDK | Linux    |
		| java      | 11.0.5   | 11     | AdoptOpenJDK | Linux    |
		| java      | 8.0.121  | 8      | AdoptOpenJDK | Linux    |
		| java      | 8.0.111  | 8      | AdoptOpenJDK | Linux    |
		| java      | 8.0.101  | 8      | AdoptOpenJDK | Linux    |
		When I enter "sdk pin java 8"
		And I enter "sdk install java"
		Then the candidate "java" version "8.0.121" is installed
		Given the following candidate versions are available for download
		| java      | 8.0.131  | 8      | default | Linux    |
		And I enter "sdk install java"
		Then the candidate "java" version "8.0.131" is installed
		
	Scenario: A major version is pinned for a specific vendor to continuously upgrade
		Given a machine with "Linux" installed
		And the system is bootstrapped
		And the default vendor is "AdoptOpenJDK" with label "adpt"
		And an additional vendor is "Amazon" with label "amzn"
		And the following candidate versions are available for download
			| java      | 11.0.5   | 11     | AdoptOpenJDK | Linux    |
			| java      | 11.0.5   | 11     | Amazon       | Linux    |
			| java      | 8.0.121  | 8      | Amazon       | Linux    |
			| java      | 8.0.111  | 8      | AdoptOpenJDK | Linux    |
			| java      | 8.0.111  | 8      | Amazon       | Linux    |
			| java      | 8.0.101  | 8      | AdoptOpenJDK | Linux    |
			| java      | 8.0.101  | 8      | Amazon       | Linux    |
		When I enter "sdk pin java 8 adpt"
		And I enter "sdk install java"
		Then the candidate "java" version "8.0.111" is installed
		Given the following candidate versions are available for download
			| java      | 8.0.121  | 8      | AdoptOpenJDK | Linux    |
		And I enter "sdk install java"
		Then the candidate "java" version "8.0.121" is installed
