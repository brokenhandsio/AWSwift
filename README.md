# AWSwift
A Native Swift 3 SDK for AWS Services, for use both on device and on servers! Supports iOS, macOS, tvOS and Linux.

## Aims

We believe that Swift has the potential to be everywhere - from running the applications on your mobile devices, to powering backends on servers and everything from scripting to websites in between. AWS is the most popular cloud computing provider and in order for us to be able to interact with it on any platform we need a native SDK. Whether it be deploying EC2 instances from scripts, to interacting with massive DynamoDB databases, we want AWSwift to do it all! 

## Supported Services

The list of AWS services we currently support are:
* DynamoDB

## Installation

AWSwift can be installed using Cocoapods and the Swift Package Manager.

### Cocoapods

Coming soon...

### Swift Package Manager

To use AWSwift, just include it as a dependency in your `Package.swift` file:

```swift
let package = Package(
    name: "MyPackage",
    dependencies: [
        .Package(url: "https://github.com/brokenhandsio/AWSwift.git", majorVersion: 0)
    ]
)

```

## Usage

### DynamoDB

Create an instance of the `AWSwiftDynamoDb` with your access ID and access Key Secret:

```swift

let dynamoDb = AWSwiftDynamoDb(awsAccessKeyId: accessID, awsAccessKeySecret: accessSecret)
```

Create a `DynamoDbTable` with the details for the table:

```swift
let petsTable = DynamoDbTable(tableName: "Pets", partitionKey: "AnimalType", sortKey: "Name")
```

Then perform the action that you want. For a get, you need a key and use it as so:

```swift
let key = [
    "AnimalType": ["S": "Dog"],
    "Name": ["S" : "Fred"]
]

dynamoDb.getItem(table: petsTable, key: key) {
    response in
    print(response)
}
```

## Vapor Providers

