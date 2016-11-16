protocol DynamoDbAction {
    func getItem(table: DynamoDbTable, key: [String: [String: String]], completion: @escaping ((_ itemJsonString: String) -> Void))
}
