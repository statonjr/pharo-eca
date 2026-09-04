"
Opt-in end-to-end test against a real `eca server` process. Skipped when no
eca binary is resolvable, so CI and images without ECA stay green.
"
Class {
	#name : 'EcaIntegrationTest',
	#superclass : 'TestCase',
	#instVars : [
		'client'
	],
	#category : 'ECA-Tests-Tests',
	#package : 'ECA-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
EcaIntegrationTest >> setUp [
	super setUp.
	[ EcaServerLocator new resolve ]
		on: EcaError
		do: [ :e | self skip: 'eca binary not installed' ].
	client := EcaClient new
]

{ #category : 'running' }
EcaIntegrationTest >> tearDown [
	client ifNotNil: [ :c | [ c stopGracefully ] on: Error do: [ :e | ] ].
	super tearDown
]

{ #category : 'tests' }
EcaIntegrationTest >> testStartHandshakeAndShutdown [
	client start.
	self assert: client isRunning.
	self deny: client session models isEmpty.
	client stopGracefully
]
