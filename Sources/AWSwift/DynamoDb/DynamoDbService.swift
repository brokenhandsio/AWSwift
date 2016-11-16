enum DynamoDbService: AwsService {
    func getServiceHostname() -> String {
        return "dynamodb"
    }
    
    func getAmzTarget() -> String {
        switch self {
        case .getItem:
            return "DynamoDB_20120810.GetItem"
        }
    }
    
    case getItem
}
