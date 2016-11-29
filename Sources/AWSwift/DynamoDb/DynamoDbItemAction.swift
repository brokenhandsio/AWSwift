protocol DynamoDbItemAction {
    func getItem(keyValues: DynamoDbTableKeyValues, completion: @escaping ((_ itemJsonString: String?, _ error: AwsRequestErorr?) -> Void))
    func putItem(item: [String: Any], condition: String, conditionAttributes: [String: [String:String]], completion: @escaping ((_ resposne: String?, _ error: AwsRequestErorr?) -> Void))
    func deleteItem(keyValue: DynamoDbTableKeyValues, conditionExpression: String?, returnValues: DynamoDbReturnValue?, completion: @escaping ((_ response: String?, _ error: AwsRequestErorr?) -> Void))
}
