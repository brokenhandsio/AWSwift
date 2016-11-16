public struct DynamoDbTable {
    let tableName: String
    let partitionKey: String
    let sortKey: String?
    
    public init(tableName: String, partitionKey: String, sortKey: String?) {
        self.tableName = tableName
        self.partitionKey = partitionKey
        self.sortKey = sortKey
    }
}
