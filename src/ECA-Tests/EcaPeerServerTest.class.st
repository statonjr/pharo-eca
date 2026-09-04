Class {
	#name : 'EcaPeerServerTest',
	#superclass : 'TestCase',
	#category : 'ECA-Tests-Tests',
	#package : 'ECA-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
EcaPeerServerTest >> testAnswersRequestedPortWhenFree [
	self assert: (EcaPeerServer availablePortFrom: 18086) equals: 18086
]

{ #category : 'tests' }
EcaPeerServerTest >> testStepsToNextPortWhenBusy [
	"Two peers, one configured port: the second must bind port + 1
	 instead of dying with SocketError in its forked listen loop."

	| first second |
	first := second := nil.
	[
	first := EcaPeerServer new startOn: 18086.
	second := EcaPeerServer new startOn: 18086.
	self assert: first port equals: 18086.
	self assert: second port equals: 18087 ]
		ensure: [
			first ifNotNil: [ :s | s stop ].
			second ifNotNil: [ :s | s stop ] ]
]

{ #category : 'tests' }
EcaPeerServerTest >> testPortProbeReleasesTheSocket [
	"Probing must not itself squat the port."

	self assert: (EcaPeerServer isPortAvailable: 18086).
	self assert: (EcaPeerServer isPortAvailable: 18086)
]
