enum DynamoDbService: AwsService {
    func getServiceHostname() -> String {
        return "dynamodb"
    }
    
    func getAmzTarget() -> String {
        switch self {
        case .getItem:
            return "DynamoDB_20120810.GetItem"
        case .putItem:
            return "DynamoDB_20120810.PutItem"
        case .updateItem:
            return "DynamoDB_20120810.UpdateItem"
        case .deleteItem:
            return "DynamoDB_20120810.DeleteItem"
        case .scan:
            return "DynamoDB_20120810.Scan"
        case .createTable:
            return "DynamoDB_20120810.CreateTable"
        case .deleteTable:
            return "DynamoDB_20120810.DeleteTable"
        case .updateTable:
            return "DynamoDB_20120810.UpdateTable"
        }
    }
    
    case getItem
    case putItem
    case updateItem
    case deleteItem
    case scan
    case createTable
    case deleteTable
    case updateTable
}
