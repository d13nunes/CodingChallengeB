import UIKit

class ImageCache {
    static let shared: NSCache<NSURL, UIImage> = { () -> NSCache<NSURL, UIImage> in
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 100 // Maximum 100 images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        return cache
    }()
}
