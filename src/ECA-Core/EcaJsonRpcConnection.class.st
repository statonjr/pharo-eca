"
JSON-RPC 2.0 connection over a TEcaTransport user:
- correlates request ids with responses (semaphore per pending request)
- dispatches server notifications to registered handler blocks
- answers server -> client requests via registered request handlers
- runs a background reader Process
"
Class {
	#name : 'EcaJsonRpcConnection',
	#superclass : 'Object',
	#instVars : [
		'transport',
		'framer',
		'nextId',
		'pendingRequests',
		'notificationHandlers',
		'requestHandlers',
		'readerProcess',
		'writeLock'
	],
	#category : 'ECA-Core-Protocol',
	#package : 'ECA-Core',
	#tag : 'Protocol'
}

{ #category : 'instance creation' }
EcaJsonRpcConnection class >> on: aTransport [
	^ self new
		setTransport: aTransport;
		yourself
]

{ #category : 'initialization' }
EcaJsonRpcConnection >> setTransport: aTransport [
	transport := aTransport.
	framer := EcaJsonRpcFramer new.
	nextId := 1.
	pendingRequests := Dictionary new.
	notificationHandlers := Dictionary new.
	requestHandlers := Dictionary new.
	writeLock := Mutex new
]

{ #category : 'lifecycle' }
EcaJsonRpcConnection >> start [
	readerProcess := [ self readLoop ]
		forkAt: Processor userBackgroundPriority
		named: 'eca jsonrpc reader'
]

{ #category : 'lifecycle' }
EcaJsonRpcConnection >> stop [
	readerProcess ifNotNil: [ :p | p terminate ].
	pendingRequests valuesDo: [ :pending | pending signalAbandoned ].
	pendingRequests removeAll
]

{ #category : 'registering' }
EcaJsonRpcConnection >> onNotification: aMethodString do: aBlock [
	notificationHandlers at: aMethodString put: aBlock
]

{ #category : 'registering' }
EcaJsonRpcConnection >> onRequest: aMethodString do: aBlock [
	"aBlock receives params and must answer the result object."

	requestHandlers at: aMethodString put: aBlock
]

{ #category : 'sending' }
EcaJsonRpcConnection >> sendNotification: aMethodString params: anObject [
	self writeMessage: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'method' put: aMethodString;
		at: 'params' put: anObject;
		yourself)
]

{ #category : 'sending' }
EcaJsonRpcConnection >> sendRequest: aMethodString params: anObject [
	^ self sendRequest: aMethodString params: anObject timeout: 60 seconds
]

{ #category : 'sending' }
EcaJsonRpcConnection >> sendRequest: aMethodString params: anObject timeout: aDuration [
	| id pending |
	id := nextId.
	nextId := nextId + 1.
	pending := EcaPendingRequest id: id.
	pendingRequests at: id put: pending.
	self writeMessage: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: id;
		at: 'method' put: aMethodString;
		at: 'params' put: anObject;
		yourself).
	^ pending waitTimeout: aDuration
]

{ #category : 'private' }
EcaJsonRpcConnection >> writeMessage: aDictionary [
	writeLock critical: [
		framer writeMessage: aDictionary on: transport binaryWriteStream ]
]

{ #category : 'private' }
EcaJsonRpcConnection >> readLoop [
	[ transport isRunning ] whileTrue: [
		| message |
		message := framer readMessageFrom: transport binaryReadStream.
		message
			ifNil: [ ^ self ]
			ifNotNil: [ self dispatch: message ] ]
]

{ #category : 'private' }
EcaJsonRpcConnection >> dispatch: aMessage [
	(aMessage includesKey: 'method')
		ifTrue: [
			(aMessage includesKey: 'id')
				ifTrue: [ self handleServerRequest: aMessage ]
				ifFalse: [ self handleNotification: aMessage ] ]
		ifFalse: [ self handleResponse: aMessage ]
]

{ #category : 'private' }
EcaJsonRpcConnection >> handleNotification: aMessage [
	(notificationHandlers at: (aMessage at: 'method') ifAbsent: [ nil ])
		ifNotNil: [ :handler |
			[ handler value: (aMessage at: 'params' ifAbsent: [ Dictionary new ]) ]
				on: Error
				do: [ :e | e traceCr ] ]
]

{ #category : 'private' }
EcaJsonRpcConnection >> handleServerRequest: aMessage [
	| handler result |
	handler := requestHandlers at: (aMessage at: 'method') ifAbsent: [
		^ self writeMessage: (Dictionary new
			at: 'jsonrpc' put: '2.0';
			at: 'id' put: (aMessage at: 'id');
			at: 'error' put: (Dictionary new
				at: 'code' put: -32601;
				at: 'message' put: 'Method not found';
				yourself);
			yourself) ].
	result := handler value: (aMessage at: 'params' ifAbsent: [ Dictionary new ]).
	self writeMessage: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: (aMessage at: 'id');
		at: 'result' put: result;
		yourself)
]

{ #category : 'private' }
EcaJsonRpcConnection >> handleResponse: aMessage [
	(pendingRequests removeKey: (aMessage at: 'id') ifAbsent: [ nil ])
		ifNotNil: [ :pending | pending resolveWith: aMessage ]
]
