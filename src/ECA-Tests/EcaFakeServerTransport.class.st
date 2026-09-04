"
In-memory transport for tests: client writes are parsed and answered from a
scripted response table (method name -> result), plus queued notifications,
without any external process. Composes TEcaTransport like the production
transports.
"
Class {
	#name : 'EcaFakeServerTransport',
	#superclass : 'Object',
	#traits : 'TEcaTransport',
	#classTraits : 'TEcaTransport classTrait',
	#instVars : [
		'running',
		'toClientQueue',
		'sentMessages',
		'scriptedResults',
		'framer',
		'clientBuffer'
	],
	#category : 'ECA-Tests-Fakes',
	#package : 'ECA-Tests',
	#tag : 'Fakes'
}

{ #category : 'initialization' }
EcaFakeServerTransport >> initialize [
	super initialize.
	running := false.
	framer := EcaJsonRpcFramer new.
	toClientQueue := SharedQueue new.
	sentMessages := OrderedCollection new.
	scriptedResults := Dictionary new.
	clientBuffer := EcaFakeServerWriteBuffer on: self
]

{ #category : 'scripting' }
EcaFakeServerTransport >> respondTo: aMethodString with: aResultObject [
	scriptedResults at: aMethodString put: aResultObject
]

{ #category : 'scripting' }
EcaFakeServerTransport >> pushNotification: aMethodString params: params [
	self enqueueToClient: (Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'method' put: aMethodString;
		at: 'params' put: params;
		yourself)
]

{ #category : 'accessing' }
EcaFakeServerTransport >> sentMessages [
	^ sentMessages
]

{ #category : 'lifecycle' }
EcaFakeServerTransport >> start [
	running := true
]

{ #category : 'lifecycle' }
EcaFakeServerTransport >> stop [
	running := false.
	toClientQueue nextPut: nil
]

{ #category : 'testing' }
EcaFakeServerTransport >> isRunning [
	^ running
]

{ #category : 'accessing' }
EcaFakeServerTransport >> binaryReadStream [
	^ EcaFakeServerReadStream onQueue: toClientQueue
]

{ #category : 'accessing' }
EcaFakeServerTransport >> binaryWriteStream [
	^ clientBuffer
]

{ #category : 'private' }
EcaFakeServerTransport >> clientSent: aMessage [
	sentMessages add: aMessage.
	((aMessage includesKey: 'id') and: [ aMessage includesKey: 'method' ])
		ifTrue: [
			self enqueueToClient: (Dictionary new
				at: 'jsonrpc' put: '2.0';
				at: 'id' put: (aMessage at: 'id');
				at: 'result' put: (scriptedResults
						at: (aMessage at: 'method')
						ifAbsent: [ Dictionary new ]);
				yourself) ]
]

{ #category : 'private' }
EcaFakeServerTransport >> enqueueToClient: aMessage [
	| bytes |
	bytes := ReadWriteStream on: ByteArray new.
	framer writeMessage: aMessage on: bytes.
	bytes reset.
	bytes upToEnd do: [ :byte | toClientQueue nextPut: byte ]
]
