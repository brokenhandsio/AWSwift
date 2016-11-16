protocol DynamoDbTable {
    var tableName: String { get }
    var partitionKey: String { get }
    var sortKey: String? { get }
}
