"
Maps the image's Iceberg repositories (local Tonel checkouts) to ECA
workspaceFolders so the server's file tools operate on the same sources the
image loads code from.
"
Class {
	#name : 'EcaWorkspaceResolver',
	#superclass : 'Object',
	#category : 'ECA-Core-Client',
	#package : 'ECA-Core',
	#tag : 'Client'
}

{ #category : 'resolving' }
EcaWorkspaceResolver >> workspaceFolders [
	^ (IceRepository registry
		select: [ :repo | repo location notNil and: [ repo location exists ] ])
		collect: [ :repo |
			Dictionary new
				at: 'name' put: repo name;
				at: 'uri' put: 'file://' , repo location fullName;
				yourself ]
		as: Array
]
