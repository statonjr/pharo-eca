"
Lifecycle facade for the ECA server, mirroring the eca-emacs client:
start -> spawn process, `initialize` request, `initialized` notification;
then chat API (`chat/prompt`, contexts, commands, tool approval);
stopGracefully -> `shutdown` request + `exit` notification.
"
Class {
	#name : 'EcaClient',
	#superclass : 'Object',
	#instVars : [
		'transport',
		'connection',
		'session'
	],
	#classVars : [
		'Default'
	],
	#category : 'ECA-Core-Client',
	#package : 'ECA-Core',
	#tag : 'Client'
}

{ #category : 'accessing' }
EcaClient class >> default [
	^ Default ifNil: [ Default := self new ]
]

{ #category : 'class initialization' }
EcaClient class >> reset [
	Default ifNotNil: [ :c | [ c stopGracefully ] on: Error do: [ :e | ] ].
	Default := nil
]

{ #category : 'accessing' }
EcaClient >> session [
	^ session ifNil: [ session := EcaSession new ]
]

{ #category : 'accessing' }
EcaClient >> transport [
	^ transport
]

{ #category : 'lifecycle' }
EcaClient >> start [
	| initResult |
	transport := EcaSubprocessTransport command: {
		EcaServerLocator new resolve.
		'server' }.
	transport start.
	connection := EcaJsonRpcConnection on: transport.
	self registerHandlers.
	connection start.
	initResult := connection
		sendRequest: 'initialize'
		params: (Dictionary new
			at: 'processId' put: nil;
			at: 'clientInfo' put: (Dictionary new
				at: 'name' put: 'pharo-eca';
				at: 'version' put: '0.1.0';
				yourself);
			at: 'capabilities' put: (Dictionary new
				at: 'codeAssistant' put: (Dictionary new
					at: 'chat' put: true;
					yourself);
				yourself);
			at: 'initializationOptions' put: Dictionary new;
			at: 'workspaceFolders' put: EcaWorkspaceResolver new workspaceFolders;
			yourself).
	self session updateFromInitialize: initResult.
	connection sendNotification: 'initialized' params: Dictionary new
]

{ #category : 'lifecycle' }
EcaClient >> stopGracefully [
	connection ifNotNil: [ :c |
		[ c sendRequest: 'shutdown' params: Dictionary new timeout: 5 seconds ]
			on: Error
			do: [ :e | ].
		[ c sendNotification: 'exit' params: Dictionary new ]
			on: Error
			do: [ :e | ].
		c stop ].
	transport ifNotNil: [ :t | t stop ]
]

{ #category : 'testing' }
EcaClient >> isRunning [
	^ transport notNil and: [ transport isRunning ]
]

{ #category : 'private' }
EcaClient >> registerHandlers [
	connection
		onNotification: 'chat/contentReceived'
		do: [ :params | self session chatContentReceived: params ].
	connection
		onNotification: 'chat/cleared'
		do: [ :params | self session chatCleared: params ].
	connection
		onNotification: 'config/updated'
		do: [ :params | self session configUpdated: params ].
	connection
		onNotification: 'tool/serverUpdated'
		do: [ :params | self session toolServerUpdated: params ].
	connection
		onNotification: '$/showMessage'
		do: [ :params | self session showMessage: params ]
]

{ #category : 'api - chat' }
EcaClient >> prompt: aString inChat: chatIdOrNil [
	"Omit optional keys entirely when absent: the server rejects blank/null
	 chat ids (it mints one and returns it when the field is omitted)."

	| params |
	params := Dictionary new.
	params at: 'message' put: aString.
	chatIdOrNil ifNotNil: [ params at: 'chatId' put: chatIdOrNil ].
	self session selectedModel ifNotNil: [ :model |
		params at: 'model' put: model ].
	self session selectedAgent ifNotNil: [ :agent |
		params at: 'agent' put: agent ].
	^ connection sendRequest: 'chat/prompt' params: params timeout: 5 minutes
]

{ #category : 'api - chat' }
EcaClient >> queryContext: aString inChat: chatId [
	^ connection
		sendRequest: 'chat/queryContext'
		params: (Dictionary new
			at: 'chatId' put: chatId;
			at: 'query' put: aString;
			yourself)
]

{ #category : 'api - chat' }
EcaClient >> queryCommands: aString inChat: chatId [
	^ connection
		sendRequest: 'chat/queryCommands'
		params: (Dictionary new
			at: 'chatId' put: chatId;
			at: 'query' put: aString;
			yourself)
]

{ #category : 'api - tools' }
EcaClient >> approveToolCall: toolCallId inChat: chatId [
	^ connection
		sendRequest: 'chat/toolCallApprove'
		params: (Dictionary new
			at: 'chatId' put: chatId;
			at: 'toolCallId' put: toolCallId;
			yourself)
]

{ #category : 'api - tools' }
EcaClient >> rejectToolCall: toolCallId inChat: chatId [
	^ connection
		sendRequest: 'chat/toolCallReject'
		params: (Dictionary new
			at: 'chatId' put: chatId;
			at: 'toolCallId' put: toolCallId;
			yourself)
]

{ #category : 'api - chat' }
EcaClient >> stopPrompt: chatId [
	^ connection
		sendRequest: 'chat/promptStop'
		params: (Dictionary new at: 'chatId' put: chatId; yourself)
]
