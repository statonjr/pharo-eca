"
Correlation record for one in-flight JSON-RPC request: the sender blocks on a
semaphore until the reader process resolves it with the response message.
"
Class {
	#name : 'EcaPendingRequest',
	#superclass : 'Object',
	#instVars : [
		'id',
		'semaphore',
		'response'
	],
	#category : 'ECA-Core-Protocol',
	#package : 'ECA-Core',
	#tag : 'Protocol'
}

{ #category : 'instance creation' }
EcaPendingRequest class >> id: anInteger [
	^ self new
		setId: anInteger;
		yourself
]

{ #category : 'initialization' }
EcaPendingRequest >> setId: anInteger [
	id := anInteger.
	semaphore := Semaphore new
]

{ #category : 'resolving' }
EcaPendingRequest >> resolveWith: aResponseMessage [
	response := aResponseMessage.
	semaphore signal
]

{ #category : 'resolving' }
EcaPendingRequest >> signalAbandoned [
	response := nil.
	semaphore signal
]

{ #category : 'waiting' }
EcaPendingRequest >> waitTimeout: aDuration [
	"Answer the JSON-RPC result. Signal EcaError on error response or timeout."

	(semaphore waitTimeoutMSecs: aDuration asMilliSeconds) ifTrue: [
		^ EcaError signal: 'Request ' , id asString , ' timed out' ].
	response ifNil: [ ^ EcaError signal: 'Connection closed' ].
	(response includesKey: 'error') ifTrue: [
		^ EcaError signal:
			((response at: 'error') at: 'message' ifAbsent: [ 'Unknown ECA error' ]) ].
	^ response at: 'result' ifAbsent: [ nil ]
]
