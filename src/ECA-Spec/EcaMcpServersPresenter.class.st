"
Lists MCP servers reported via tool/serverUpdated with their status
(running / starting / failed / stopped) and tool counts.
"
Class {
	#name : 'EcaMcpServersPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'client',
		'serverTable'
	],
	#category : 'ECA-Spec-Presenters',
	#package : 'ECA-Spec',
	#tag : 'Presenters'
}

{ #category : 'initialization' }
EcaMcpServersPresenter >> setModelBeforeInitialization: anEcaClient [
	client := anEcaClient
]

{ #category : 'initialization' }
EcaMcpServersPresenter >> initializePresenters [
	serverTable := self newTable
		addColumn: (SpStringTableColumn
				title: 'Server'
				evaluated: [ :each | each at: 'name' ifAbsent: [ '?' ] ]);
		addColumn: (SpStringTableColumn
				title: 'Status'
				evaluated: [ :each | each at: 'status' ifAbsent: [ '?' ] ]);
		addColumn: (SpStringTableColumn
				title: 'Tools'
				evaluated: [ :each |
					(each at: 'tools' ifAbsent: [ #(  ) ]) size asString ]);
		items: client session mcpServers values;
		yourself.
	client session announcer
		when: EcaSessionChanged
		do: [ :ann | serverTable items: client session mcpServers values ]
		for: self
]

{ #category : 'layout' }
EcaMcpServersPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: serverTable;
		yourself
]

{ #category : 'initialization' }
EcaMcpServersPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'ECA MCP Servers';
		initialExtent: 480 @ 320
]
