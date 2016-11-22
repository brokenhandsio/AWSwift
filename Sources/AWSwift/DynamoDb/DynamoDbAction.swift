protocol DynamoDbAction {
    func getItem(table: DynamoDbTable, keyValues: DynamoDbTableKeyValues, completion: @escaping ((_ itemJsonString: String) -> Void))
    func putItem(table: DynamoDbTable, item: [String: Any], condition: String, conditionAttributes: [String: [String:String]], completion: @escaping ((_ error: Error?) -> Void))
}
