public struct DynamoDbTable {
    
    // MARK: - Properties
    
    // TOOD sort out access
    
    let tableName: String
    let partitionKey: String
    let sortKey: String?
    let connectionManager: ConnectionManager
    
    
    // MARK: - Initialiser
    
    /**
        Initialiser for a table in DynamoDb. You can use the table object to perform all the actions you need
        that involve tables, such as creation and deletion of tables, putting items, deleting items etc
     
        - Parameters:
            - tableName: The name of the table
            - partitionKey: The name of the partition key
            - sortKey: The name of the optional sort key
            - connectionManager: The connectionManager to connect to DynamoDb
     */
    public init(tableName: String, partitionKey: String, sortKey: String?, connectionManager: ConnectionManager) {
        self.tableName = tableName
        self.partitionKey = partitionKey
        self.sortKey = sortKey
        self.connectionManager = connectionManager
    }
}

// MARK = DynamoDbAction

// TODO documentation
extension DynamoDbTable: DynamoDbItemAction {
    public func putItem(item: [String : Any], condition: String, conditionAttributes: [String : [String : String]], completion: @escaping ((String?, AwsRequestErorr?) -> Void)) {
        
        let request = [
            "TableName": tableName,
            "Item": item,
            "ConditionExpression": condition,
            "ExpressionAttributeValues": conditionAttributes
            ] as [String: Any]
        
        connectionManager.request(request, method: .post, service: DynamoDbService.putItem) { (response, error) in
            completion(response, error)
        }
    }
    
    public func getItem(keyValues: DynamoDbTableKeyValues, completion: @escaping ((String?, AwsRequestErorr?) -> Void)) {
        var key = [
            partitionKey: [
                "S": keyValues.partitionKeyValue
            ]
        ]
        
        if let sortKey = sortKey {
            guard let sortKeyValue = keyValues.sortKeyValue else {
                fatalError("Table has sort key but no sort key specified")
            }
            
            key[sortKey] = ["S" :sortKeyValue]
        }
        
        let request = [
            "TableName": tableName,
            "Key": key
            ] as [String: Any]
        
        connectionManager.request(request, method: .post, service: DynamoDbService.getItem) { (response, error) in
            completion(response, error)
        }
        
    }
    
    public func deleteItem(keyValue: DynamoDbTableKeyValues, conditionExpression: String?, returnValues: DynamoDbReturnValue?, completion: @escaping ((String?, AwsRequestErorr?) -> Void)) {
        
        // Check valid return value
        if let returnValues = returnValues {
            switch returnValues {
            case .none, .allOld: break
            default:
                // Invalid return type
                completion(nil, AwsRequestErorr.failed(message: "Invalid return value for delete"))
            }
        }
        
        var key = [
            partitionKey: [
                "S": keyValue.partitionKeyValue
            ]
        ]
        
        if let sortKey = sortKey {
            guard let sortKeyValue = keyValue.sortKeyValue else {
                fatalError("Table has sort key but no sort key specified")
            }
            
            key[sortKey] = ["S" :sortKeyValue]
        }
        
        var request = [
            "TableName": tableName,
            "Key": key
            ] as [String: Any]
        
        if let conditionExpression = conditionExpression {
            request["ConditionExpression"] = conditionExpression
        }
        
        if let returnValues = returnValues {
            request["ReturnValues"] = returnValues.rawValue
        }
        
        connectionManager.request(request, method: .post, service: DynamoDbService.deleteItem) { (resposne, error) in
            completion(resposne, error)
        }
        
    }
    
}
