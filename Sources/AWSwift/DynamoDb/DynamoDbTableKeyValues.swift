public struct DynamoDbTableKeyValues {
    let partitionKeyValue: String
    let sortKeyValue: String?
    
    public init(partitionKeyValue: String, sortKeyValue: String?) {
        self.partitionKeyValue = partitionKeyValue
        self.sortKeyValue = sortKeyValue
    }
}
