"
Outcome of a sandboxed evaluation: ok (with the result's printString),
denied (source matched a denylist pattern), timeout, or error (the
evaluation raised).
"
Class {
	#name : 'EcaPeerSandboxResult',
	#superclass : 'Object',
	#instVars : [
		'status',
		'value',
		'message'
	],
	#category : 'ECA-Core-Peer',
	#package : 'ECA-Core',
	#tag : 'Peer'
}

{ #category : 'instance creation' }
EcaPeerSandboxResult class >> ok: aPrintString [
	^ self new setStatus: #ok value: aPrintString message: nil
]

{ #category : 'instance creation' }
EcaPeerSandboxResult class >> denied: aPattern [
	^ self new
		setStatus: #denied
		value: nil
		message: 'Denied by sandbox pattern: ' , aPattern
			, '. GET /describe lists all denied patterns.'
]

{ #category : 'instance creation' }
EcaPeerSandboxResult class >> timeout: milliseconds [
	^ self new
		setStatus: #timeout
		value: nil
		message: 'Evaluation timed out after ' , milliseconds asString , 'ms'
]

{ #category : 'instance creation' }
EcaPeerSandboxResult class >> error: aMessage [
	^ self new setStatus: #error value: nil message: aMessage
]

{ #category : 'initialization' }
EcaPeerSandboxResult >> setStatus: aSymbol value: aValue message: aMessageOrNil [
	status := aSymbol.
	value := aValue.
	message := aMessageOrNil
]

{ #category : 'accessing' }
EcaPeerSandboxResult >> value [
	^ value
]

{ #category : 'accessing' }
EcaPeerSandboxResult >> message [
	^ message
]

{ #category : 'testing' }
EcaPeerSandboxResult >> isOk [
	^ status = #ok
]

{ #category : 'testing' }
EcaPeerSandboxResult >> isDenied [
	^ status = #denied
]

{ #category : 'testing' }
EcaPeerSandboxResult >> isTimeout [
	^ status = #timeout
]

{ #category : 'testing' }
EcaPeerSandboxResult >> isError [
	^ status = #error
]
