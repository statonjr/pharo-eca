"
Fallback transport: connects to a TCP port bridged to `eca server` stdio by an
external shim, e.g.:

	socat TCP-LISTEN:7345,reuseaddr EXEC:'eca server'

Useful on setups where OSSubprocess is unavailable.
"
Class {
	#name : 'EcaSocketTransport',
	#superclass : 'Object',
	#traits : 'TEcaTransport',
	#classTraits : 'TEcaTransport classTrait',
	#instVars : [
		'host',
		'port',
		'socketStream'
	],
	#category : 'ECA-Core-Transport',
	#package : 'ECA-Core',
	#tag : 'Transport'
}

{ #category : 'instance creation' }
EcaSocketTransport class >> host: aString port: anInteger [
	^ self new
		host: aString;
		port: anInteger;
		yourself
]

{ #category : 'accessing' }
EcaSocketTransport >> host: aString [
	host := aString
]

{ #category : 'accessing' }
EcaSocketTransport >> port: anInteger [
	port := anInteger
]

{ #category : 'lifecycle' }
EcaSocketTransport >> start [
	socketStream := ZdcSocketStream openConnectionToHostNamed: host port: port.
	socketStream binary
]

{ #category : 'lifecycle' }
EcaSocketTransport >> stop [
	socketStream ifNotNil: [ :s | [ s close ] on: Error do: [ :e | ] ].
	socketStream := nil
]

{ #category : 'testing' }
EcaSocketTransport >> isRunning [
	^ socketStream notNil and: [ socketStream isConnected ]
]

{ #category : 'accessing' }
EcaSocketTransport >> binaryReadStream [
	^ socketStream
]

{ #category : 'accessing' }
EcaSocketTransport >> binaryWriteStream [
	^ socketStream
]
