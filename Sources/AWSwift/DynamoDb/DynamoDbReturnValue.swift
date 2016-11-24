public enum DynamoDbReturnValue: String {
    case none = "NONE"
    case allOld = "ALL_OLD"
    case updatedOld = "UPDATED_OLD"
    case allNew = "ALL_NEW"
    case updatedNew = "UPDATED_NEW"
}
