"
Transport contract to an ECA server process. Users of this trait:
- EcaSubprocessTransport (stdio via OSSubprocess, default)
- EcaSocketTransport (TCP fallback via an external stdio<->tcp shim)
- EcaFakeServerTransport (in-memory, for tests)
"
Trait {
	#name : 'TEcaTransport',
	#category : 'ECA-Core-Transport',
	#package : 'ECA-Core',
	#tag : 'Transport'
}

{ #category : 'lifecycle' }
TEcaTransport >> start [
	^ self explicitRequirement
]

{ #category : 'lifecycle' }
TEcaTransport >> stop [
	^ self explicitRequirement
]

{ #category : 'lifecycle' }
TEcaTransport >> restart [
	self stop.
	self start
]

{ #category : 'testing' }
TEcaTransport >> isRunning [
	^ self explicitRequirement
]

{ #category : 'accessing' }
TEcaTransport >> binaryReadStream [
	"Server -> client bytes (server stdout)."

	^ self explicitRequirement
]

{ #category : 'accessing' }
TEcaTransport >> binaryWriteStream [
	"Client -> server bytes (server stdin)."

	^ self explicitRequirement
]
