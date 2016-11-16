public struct AWSwiftDynamoDB: DynamoDbAction {
    
    fileprivate let awsAccessKeyId: String
    fileprivate let awsAccessKeySecret: String
    
    public init(awsAccessKeyId: String, awsAccessKeySecret: String) {
        self.awsAccessKeyId = awsAccessKeyId
        self.awsAccessKeySecret = awsAccessKeySecret
    }
    
    public func getItem(table: DynamoDbTable, key: [String : String], completion: @escaping ((_ itemJsonString: String) -> Void)) {
        let request = [
            "TableName": table.tableName,
            "Key": key
            ] as [String: Any]
        
        let awsReqeust = AwsRequest(awsAccessKeyId: awsAccessKeyId, awsAccessKeySecret: awsAccessKeySecret, service: DynamoDbService.getItem, region: .euWest1, request: request, requestMethod: .post)
        awsReqeust.makeRequest { (jsonResposne, error) in
            completion(jsonResposne!)
        }
    }
}
