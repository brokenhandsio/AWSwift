import Foundation

struct AwsRequest {
    
    fileprivate let awsAccessKeyId: String
    fileprivate let awsAccessKeySecret: String
    fileprivate let service: AwsService
    fileprivate let region: AwsRegion
    fileprivate let request: [String: Any]
    fileprivate let requestMethod: HttpMethod
    
    init(awsAccessKeyId: String, awsAccessKeySecret: String, service: AwsService, region: AwsRegion, request: [String: Any], requestMethod: HttpMethod) {
        self.awsAccessKeyId = awsAccessKeyId
        self.awsAccessKeySecret = awsAccessKeySecret
        self.service = service
        self.region = region
        self.request = request
        self.requestMethod = requestMethod
    }
    
    func makeRequest(onCompletion: (_ jsonResponse: String?, _ error: String?) -> Void) {
        let headerHost = "\(service.getServiceHostname()).\(region.rawValue).amazonaws.com"
        let urlString = "https://\(headerHost)"
        let url = URL(string: urlString)!
        var urlRequest = URLRequest(url: url)
        let requestDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        let requestDateString = dateFormatter.string(from: requestDate)
        let jsonData = try? JSONSerialization.data(withJSONObject: request, options: .prettyPrinted)
        
        guard let json = jsonData else {
            onCompletion(nil, "Could not convert request to JSON")
            return
        }
        
        urlRequest.httpMethod = requestMethod.rawValue
        urlRequest.httpBody = json
        
        urlRequest.setValue(requestDateString, forHTTPHeaderField: "X-Amz-Date")
        urlRequest.setValue(headerHost, forHTTPHeaderField: "Host")
        urlRequest.setValue(service.getAmzTarget(), forHTTPHeaderField: "X-Amz-Target")
        urlRequest.setValue("application/x-amz-json-1.0", forHTTPHeaderField: "Content-Type")
        
        let headerSigner = HeaderSignerGenerator(awsAccessId: awsAccessKeyId, awsAccessSecret: awsAccessKeySecret)
        
        let authHeader = headerSigner.getAuthHeader(forRequest: request, requestDate: requestDate, service: service, region: region, requestMethod: requestMethod)
        
        urlRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: urlRequest) {
            data, response, error in
            
            // TODO
            if let data = data {
                print("Data was \(data) - \(String(data: data, encoding: .utf8))")
            }
            print("Response was \(response)")
            print("Error was \(error)")
        }
        
        dataTask.resume()
        
    }
    
}

public enum AwsRequestErorr: Error {
    case failed(message: String)
}
