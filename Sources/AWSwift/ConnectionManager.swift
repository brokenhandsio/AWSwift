/**
    This struct deals with aspects of connecting to AWS API, mainly to do with handling authentication and endpoints
    for running DynamoDB locally
 */
public struct ConnectionManager {
    
    // MARK: - Properties
    internal let accessId: String
    internal let accessSecret: String
    internal let region: AwsRegion
    
    // MARK: - Initialiser
    
    /**
        Initialiser for the `ConnectionManager` which takes the ID and Secret for connecting to the AWS Service
     
        - Parameters:
            - accessId: The Access ID to connect to the AWS service
            - accessSecret: The Access Secret for the ID to connect to the AWS service
            - region: The region the service is running in
     */
    public init(accessId: String, accessSecret: String, region: AwsRegion) {
        self.accessId = accessId
        self.accessSecret = accessSecret
        self.region = region
    }
    
    internal func request(_ request: [String: Any], method: HttpMethod, service: AwsService, completion: ((_ response: String?, _ error: AwsRequestErorr?) -> Void)?) {
        
        let awsRequest = AwsRequest(awsAccessKeyId: accessId, awsAccessKeySecret: accessSecret, service: service, region: region, request: request, requestMethod: method)
        awsRequest.makeRequest { (jsonResponse, error) in
            if let error = error {
                print("We did error: \(error)")
                completion?(nil, error)
            }
            else {
                print("Success")
            }
        }
        
    }
}
