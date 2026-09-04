Class {
	#name : 'EcaPeerSandboxTest',
	#superclass : 'TestCase',
	#category : 'ECA-Tests-Tests',
	#package : 'ECA-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
EcaPeerSandboxTest >> testEvaluatesSimpleExpression [
	| result |
	result := EcaPeerSandbox evaluate: '3 + 4'.
	self assert: result isOk.
	self assert: result value equals: '7'
]

{ #category : 'tests' }
EcaPeerSandboxTest >> testDeniesBlockedPattern [
	| result |
	result := EcaPeerSandbox evaluate: 'LibC uniqueInstance system: ''ls'''.
	self assert: result isDenied.
	self assert: (result message includesSubstring: 'LibC')
]

{ #category : 'tests' }
EcaPeerSandboxTest >> testDeniesPeerServerControl [
	self assert: (EcaPeerSandbox evaluate: 'EcaPeerServer stop') isDenied
]

{ #category : 'tests' }
EcaPeerSandboxTest >> testTimesOut [
	| oldTimeout result |
	oldTimeout := EcaPeerSandbox timeoutMs.
	[
	EcaPeerSandbox timeoutMs: 100.
	result := EcaPeerSandbox evaluate: '[ true ] whileTrue'.
	self assert: result isTimeout.
	self assert: (result message includesSubstring: '100ms') ]
		ensure: [ EcaPeerSandbox timeoutMs: oldTimeout ]
]

{ #category : 'tests' }
EcaPeerSandboxTest >> testErrorsAreCaptured [
	| result |
	result := EcaPeerSandbox evaluate: '1/0'.
	self assert: result isError.
	self assert: (result message includesSubstring: 'ZeroDivide')
]
