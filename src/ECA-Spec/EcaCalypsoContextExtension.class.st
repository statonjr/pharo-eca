"
Bridges the Calypso browser and ECA context: computes the Tonel file path of
the selected class/method inside its Iceberg repository so it can be attached
to a chat prompt as file context (`@` context in other ECA clients).
"
Class {
	#name : 'EcaCalypsoContextExtension',
	#superclass : 'Object',
	#category : 'ECA-Spec-Calypso',
	#package : 'ECA-Spec',
	#tag : 'Calypso'
}

{ #category : 'resolving' }
EcaCalypsoContextExtension class >> contextForClass: aClass [
	"Answer a context Dictionary {type. path} for aClass' Tonel file, or nil
	 when the class is not managed by any Iceberg repository."

	| package repo |
	package := aClass package ifNil: [ ^ nil ].
	repo := IceRepository registry
		detect: [ :each | each includesPackageNamed: package name ]
		ifNone: [ ^ nil ].
	^ Dictionary new
		at: 'type' put: 'file';
		at: 'path' put: (repo location / repo subdirectory / package name
				/ (aClass instanceSide name , '.class.st')) fullName;
		yourself
]
