Class {
	#name : 'EcaClientTest',
	#superclass : 'TestCase',
	#instVars : [
		'transport',
		'connection'
	],
	#category : 'ECA-Tests-Tests',
	#package : 'ECA-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
EcaClientTest >> setUp [
	super setUp.
	transport := EcaFakeServerTransport new.
	transport start.
	connection := EcaJsonRpcConnection on: transport.
	connection start
]

{ #category : 'running' }
EcaClientTest >> tearDown [
	connection stop.
	transport stop.
	super tearDown
]

{ #category : 'tests' }
EcaClientTest >> testInitializeRoundTrip [
	| result |
	transport
		respondTo: 'initialize'
		with: (Dictionary new
			at: 'models' put: #( 'deepseek/deepseek-chat' );
			at: 'chatDefaultModel' put: 'deepseek/deepseek-chat';
			yourself).
	result := connection
		sendRequest: 'initialize'
		params: Dictionary new
		timeout: 5 seconds.
	self assert: (result at: 'chatDefaultModel') equals: 'deepseek/deepseek-chat'
]

{ #category : 'tests' }
EcaClientTest >> testNotificationDispatch [
	| received semaphore |
	semaphore := Semaphore new.
	connection onNotification: 'chat/contentReceived' do: [ :params |
		received := params.
		semaphore signal ].
	transport
		pushNotification: 'chat/contentReceived'
		params: (Dictionary new
			at: 'chatId' put: 'chat-1';
			at: 'role' put: 'assistant';
			at: 'content' put: (Dictionary new
				at: 'type' put: 'text';
				at: 'text' put: 'Hello!';
				yourself);
			yourself).
	self deny: (semaphore waitTimeoutMSecs: 2000).
	self assert: (received at: 'chatId') equals: 'chat-1'
]

{ #category : 'tests' }
EcaClientTest >> testSessionAccumulatesChatContent [
	| session |
	session := EcaSession new.
	session chatContentReceived: (Dictionary new
		at: 'chatId' put: 'chat-1';
		at: 'role' put: 'assistant';
		at: 'content' put: (Dictionary new
			at: 'type' put: 'text';
			at: 'text' put: 'Hi';
			yourself);
		yourself).
	self assert: (session chatAt: 'chat-1') contents size equals: 1.
	self assert: (session chatAt: 'chat-1') contents first text equals: 'Hi'
]

{ #category : 'tests' }
EcaClientTest >> testRequestTimeoutSignalsEcaError [
	transport stop. "no responses will arrive"
	self
		should: [
			connection
				sendRequest: 'chat/prompt'
				params: Dictionary new
				timeout: 100 milliSeconds ]
		raise: EcaError
]
