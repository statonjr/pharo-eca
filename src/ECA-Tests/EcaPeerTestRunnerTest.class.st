Class {
	#name : 'EcaPeerTestRunnerTest',
	#superclass : 'TestCase',
	#category : 'ECA-Tests-Tests',
	#package : 'ECA-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
EcaPeerTestRunnerTest >> testRunsAClassSuite [
	| report |
	report := EcaPeerTestRunner runClassNamed: 'EcaPeerSandboxTest'.
	self assert: (report at: 'tests') > 0.
	self assert: (report at: 'failures') equals: 0.
	self assert: (report at: 'errors') equals: 0.
	self assert: (report at: 'defects') isEmpty
]

{ #category : 'tests' }
EcaPeerTestRunnerTest >> testUnknownClassAnswersNil [
	self assert: (EcaPeerTestRunner runClassNamed: 'NoSuchClassZzz') isNil
]

{ #category : 'tests' }
EcaPeerTestRunnerTest >> testNonTestClassAnswersNil [
	self assert: (EcaPeerTestRunner runClassNamed: 'Object') isNil
]

{ #category : 'tests' }
EcaPeerTestRunnerTest >> testUnknownPackageAnswersNil [
	self assert: (EcaPeerTestRunner runPackageNamed: 'No-Such-Package') isNil
]
