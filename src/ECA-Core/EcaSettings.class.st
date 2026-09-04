"
Image-level ECA preferences, exposed in the Settings Browser under 'ECA'.
"
Class {
	#name : 'EcaSettings',
	#superclass : 'Object',
	#classVars : [
		'ServerPath'
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
		default: ''
]
