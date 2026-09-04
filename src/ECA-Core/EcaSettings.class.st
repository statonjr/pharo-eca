"
Image-level ECA preferences, exposed in the Settings Browser under 'ECA'.
"
Class {
	#name : 'EcaSettings',
	#superclass : 'Object',
	#classVars : [
		'ServerPath',
		'ServerArgs',
		'PeerPort'
	],
	#category : 'ECA-Core-Client',
	#package : 'ECA-Core',
	#tag : 'Client'
}

{ #category : 'accessing' }
EcaSettings class >> serverPath [
	^ ServerPath ifNil: [ '' ]
]

{ #category : 'accessing' }
EcaSettings class >> serverPath: aString [
	ServerPath := aString
]

{ #category : 'settings' }
EcaSettings class >> settingsOn: aBuilder [
	<systemsettings>
	(aBuilder group: #eca)
		label: 'ECA';
		description: 'Editor Code Assistant integration'.
	(aBuilder setting: #serverPath)
		parent: #eca;
		target: self;
		label: 'Server path';
		description: 'Absolute path to the eca executable. Empty = search $PATH.';
		default: ''.
	(aBuilder setting: #serverArgs)
		parent: #eca;
		target: self;
		label: 'Server extra args';
		description: 'Extra arguments appended to `eca server`, e.g. --verbose for debug logging (visible via ECA > Inspect Server Log). Takes effect on server restart.';
		default: ''.
	(aBuilder setting: #peerPort)
		parent: #eca;
		target: self;
		label: 'Peer server port';
		description: 'Port used by ECA > Start Peer Server.';
		default: 8086.
	(aBuilder setting: #timeoutMs)
		parent: #eca;
		target: EcaPeerSandbox;
		label: 'Peer sandbox timeout (ms)';
		description: 'Maximum wall-clock time for one /eval in the peer sandbox.';
		default: 5000
]

{ #category : 'accessing' }
EcaSettings class >> serverArgs [
	^ ServerArgs ifNil: [ '' ]
]

{ #category : 'accessing' }
EcaSettings class >> serverArgs: aString [
	ServerArgs := aString
]

{ #category : 'accessing' }
EcaSettings class >> peerPort [
	^ PeerPort ifNil: [ 8086 ]
]

{ #category : 'accessing' }
EcaSettings class >> peerPort: anInteger [
	PeerPort := anInteger
]
