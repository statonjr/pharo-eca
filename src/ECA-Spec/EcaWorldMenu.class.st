"
Top-level ECA World menu (pattern borrowed from ChatPharoState): a parent
#ECA item with children for chat, MCP servers, server lifecycle, the peer
server, the stderr log, and settings — so daily driving needs no Playground.
"
Class {
	#name : 'EcaWorldMenu',
	#superclass : 'Object',
	#category : 'ECA-Spec-Menu',
	#package : 'ECA-Spec',
	#tag : 'Menu'
}

{ #category : 'world menu' }
EcaWorldMenu class >> ecaMenuOn: aBuilder [
	<worldMenu>
	(aBuilder item: #ECA)
		order: 2.6;
		iconName: #smallTalk;
		help: 'ECA — AI pair programming (eca.dev)'
]

{ #category : 'world menu' }
EcaWorldMenu class >> openChatOn: aBuilder [
	<worldMenu>
	(aBuilder item: #'Open Chat')
		parent: #ECA;
		order: 10;
		iconName: #smallTalk;
		action: [ EcaChatPresenter open ]
]

{ #category : 'world menu' }
EcaWorldMenu class >> mcpServersOn: aBuilder [
	<worldMenu>
	(aBuilder item: #'MCP Servers')
		parent: #ECA;
		order: 20;
		iconName: #remote;
		action: [
			| client |
			client := EcaClient default.
			client isRunning ifFalse: [ client start ].
			(EcaMcpServersPresenter on: client) open ]
]

{ #category : 'world menu' }
EcaWorldMenu class >> restartServerOn: aBuilder [
	<worldMenu>
	(aBuilder item: #'Restart ECA Server')
		parent: #ECA;
		order: 30;
		iconName: #refresh;
		action: [
			EcaClient reset.
			EcaClient default start.
			UIManager default inform: 'ECA server restarted' ]
]

{ #category : 'world menu' }
EcaWorldMenu class >> serverLogOn: aBuilder [
	<worldMenu>
	(aBuilder item: #'Inspect Server Log')
		parent: #ECA;
		order: 40;
		iconName: #announcement;
		action: [
			EcaClient default transport
				ifNil: [ UIManager default inform: 'ECA server not running' ]
				ifNotNil: [ :t | t stderrLog contents inspect ] ]
]

{ #category : 'world menu' }
EcaWorldMenu class >> startPeerOn: aBuilder [
	<worldMenu>
	(aBuilder item: #'Start Peer Server')
		parent: #ECA;
		order: 50;
		iconName: #smallWindow;
		help: 'Serve /describe, /classes, /eval (sandboxed) and /test on the configured port';
		action: [
			| peer |
			peer := EcaPeerServer startOn: EcaSettings peerPort.
			UIManager default inform:
				'Peer server on port ' , peer port asString
				, (peer port = EcaSettings peerPort
					ifTrue: [ '' ]
					ifFalse: [ ' (configured port '
						, EcaSettings peerPort asString , ' was busy)' ]) ]
]

{ #category : 'world menu' }
EcaWorldMenu class >> stopPeerOn: aBuilder [
	<worldMenu>
	(aBuilder item: #'Stop Peer Server')
		parent: #ECA;
		order: 60;
		action: [
			EcaPeerServer stop.
			UIManager default inform: 'Peer server stopped' ]
]

{ #category : 'world menu' }
EcaWorldMenu class >> settingsOn: aBuilder [
	<worldMenu>
	(aBuilder item: #'ECA Settings')
		parent: #ECA;
		order: 70;
		iconName: #configuration;
		action: [
			[ SettingBrowser new changeInitialKeywords: { 'ECA' }; open ]
				on: Error
				do: [ :e | SettingBrowser new open ] ]
]
