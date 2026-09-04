"
In-image state fed by server notifications:
- models/agents/defaults from the `initialize` result and `config/updated`
- MCP server statuses from `tool/serverUpdated`
- EcaChat objects accumulating `chat/contentReceived` blocks
UI binds via the announcer (EcaSessionChanged, EcaChatContentAdded,
EcaMessageShown).
"
Class {
	#name : 'EcaSession',
	#superclass : 'Object',
	#instVars : [
		'models',
		'agents',
		'selectedModel',
		'selectedAgent',
		'chats',
		'mcpServers',
		'announcer'
	],
	#category : 'ECA-Core-Model',
	#package : 'ECA-Core',
	#tag : 'Model'
}

{ #category : 'initialization' }
EcaSession >> initialize [
	super initialize.
	models := #(  ).
	agents := #(  ).
	chats := Dictionary new.
	mcpServers := Dictionary new
]

{ #category : 'accessing' }
EcaSession >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'accessing' }
EcaSession >> models [
	^ models
]

{ #category : 'accessing' }
EcaSession >> agents [
	^ agents
]

{ #category : 'accessing' }
EcaSession >> selectedModel [
	^ selectedModel
]

{ #category : 'accessing' }
EcaSession >> selectedModel: aString [
	selectedModel := aString
]

{ #category : 'accessing' }
EcaSession >> selectedAgent [
	^ selectedAgent
]

{ #category : 'accessing' }
EcaSession >> selectedAgent: aString [
	selectedAgent := aString
]

{ #category : 'accessing' }
EcaSession >> mcpServers [
	^ mcpServers
]

{ #category : 'accessing' }
EcaSession >> chatAt: chatId [
	^ chats at: chatId ifAbsentPut: [ EcaChat id: chatId ]
]

{ #category : 'updating' }
EcaSession >> updateFromInitialize: aResult [
	aResult ifNil: [ ^ self ].
	models := aResult at: 'models' ifAbsent: [ #(  ) ].
	agents := aResult at: 'chatAgents' ifAbsent: [ #(  ) ].
	selectedModel := aResult at: 'chatDefaultModel' ifAbsent: [ nil ].
	selectedAgent := aResult at: 'chatDefaultAgent' ifAbsent: [ nil ].
	self announcer announce: EcaSessionChanged new
]

{ #category : 'updating' }
EcaSession >> configUpdated: params [
	"Since ECA 0.42.0 models/agents arrive here (async, after initialized),
	 not in the initialize response. Field names use the select* convention."

	(params at: 'chat' ifAbsent: [ nil ]) ifNotNil: [ :chatConfig |
		models := chatConfig at: 'models' ifAbsent: [ models ].
		selectedModel := chatConfig at: 'selectModel' ifAbsent: [ selectedModel ].
		agents := chatConfig
			at: 'agents'
			ifAbsent: [ chatConfig at: 'behaviors' ifAbsent: [ agents ] ].
		selectedAgent := chatConfig
			at: 'selectAgent'
			ifAbsent: [ chatConfig at: 'selectBehavior' ifAbsent: [ selectedAgent ] ] ].
	self announcer announce: EcaSessionChanged new
]

{ #category : 'updating' }
EcaSession >> chatContentReceived: params [
	| chat |
	chat := self chatAt: (params at: 'chatId').
	chat addContent: (EcaContentBlock fromDictionary: params).
	self announcer announce: (EcaChatContentAdded chat: chat)
]

{ #category : 'updating' }
EcaSession >> chatCleared: params [
	(chats at: (params at: 'chatId') ifAbsent: [ nil ]) ifNotNil: [ :chat |
		chat clearContents.
		self announcer announce: (EcaChatContentAdded chat: chat) ]
]

{ #category : 'updating' }
EcaSession >> toolServerUpdated: params [
	mcpServers at: (params at: 'name' ifAbsent: [ '?' ]) put: params.
	self announcer announce: EcaSessionChanged new
]

{ #category : 'updating' }
EcaSession >> showMessage: params [
	self announcer announce: (EcaMessageShown message: params)
]
