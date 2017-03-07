/*
 * BingController
 */

import AFNetworking

class BingController: NSObject {

    static let instance  = BingController()

    let backgroundOperationQueue = OperationQueue()

    private override init() {
        self.backgroundOperationQueue.name = "Background queue"
        super.init()
    }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    func prepare() {}
    
    public func loadSearchImages(query: String, count: Int64 = 150, offset: Int64 = 0, completion: @escaping CompletionBlock) {
        
        Log.d("Image search count: \(count), offset: \(offset) ")
        
        let urlString = "https://api.cognitive.microsoft.com/bing/v5.0"
        let bingSessionManager: AFHTTPSessionManager = AFHTTPSessionManager(baseURL: NSURL(string: urlString) as URL?)
        let requestSerializer: AFJSONRequestSerializer = AFJSONRequestSerializer()
        
        requestSerializer.setValue(Ids.bingKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        bingSessionManager.requestSerializer = requestSerializer
        bingSessionManager.responseSerializer = JSONResponseSerializerWithData()
        
        let queryEncoded: String = query.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        let bingUrl = "images/search?q=%27" + queryEncoded + "%27"
            + "&mkt=en-us&safeSearch=strict&size=large"
            + "&count=\(count + 1)"
            + "&offset=\(offset)"
        
        bingSessionManager.get(bingUrl, parameters: nil
            , success: { dataTask, response in
                completion(response, nil)
            }
            , failure: { dataTask, error in
                completion(nil, error as NSError)
        })
    }
}
