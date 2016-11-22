public struct AWSwiftDynamoDb: DynamoDbAction {
    
    fileprivate let awsAccessKeyId: String
    fileprivate let awsAccessKeySecret: String
    
    public init(awsAccessKeyId: String, awsAccessKeySecret: String) {
        self.awsAccessKeyId = awsAccessKeyId
        self.awsAccessKeySecret = awsAccessKeySecret
    }
    
    public func getItem(table: DynamoDbTable, keyValues: DynamoDbTableKeyValues, completion: @escaping ((_ itemJsonString: String) -> Void)) {
        
        var key = [
            table.partitionKey: [
                "S": keyValues.partitionKeyValue
            ]
        ]
        
        if let sortKey = table.sortKey {
            guard let sortKeyValue = keyValues.sortKeyValue else {
                fatalError("Table has sort key but no sort key specified")
            }
            
            key[sortKey] = ["S" :sortKeyValue]
        }
        
        let request = [
            "TableName": table.tableName,
            "Key": key
            ] as [String: Any]
        
        let awsReqeust = AwsRequest(awsAccessKeyId: awsAccessKeyId, awsAccessKeySecret: awsAccessKeySecret, service: DynamoDbService.getItem, region: .euWest1, request: request, requestMethod: .post)
        awsReqeust.makeRequest { (jsonResposne, error) in
            completion(jsonResposne!)
        }
    }
    
    public func putItem(table: DynamoDbTable, item: [String : Any], condition: String, conditionAttributes: [String : [String : String]], completion: @escaping ((Error?) -> Void)) {
        let request = [
            "TableName": table.tableName,
            "Item": item,
            "ConditionExpression": condition,
            "ExpressionAttributeValues": conditionAttributes
        ] as [String: Any]
        
        let awsRequest = AwsRequest(awsAccessKeyId: awsAccessKeyId, awsAccessKeySecret: awsAccessKeySecret, service: DynamoDbService.putItem, region: .euWest1, request: request, requestMethod: .post)
        awsRequest.makeRequest { (jsonResponse, error) in
            if let error = error {
                print("We did error: \(error)")
                completion(nil)
            }
            else {
                print("Success")
            }
        }
    }
}
