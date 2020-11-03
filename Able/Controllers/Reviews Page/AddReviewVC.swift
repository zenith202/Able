//
//  AddReviewVC.swift
//  Able
//
//  Created by Ziyi Liew on 21/10/20.
//

import UIKit
import Firebase
import Cosmos
import TinyConstraints

class AddReviewVC: UIViewController {
    var ref: DatabaseReference!
    var user: AbleUser?
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    lazy var cosmosView: CosmosView = {
        var view = CosmosView()
        view.settings.filledImage = UIImage(named: "RatingStarFilled")?.withRenderingMode(.alwaysOriginal)
        view.settings.emptyImage = UIImage(named: "RatingStarEmpty")?.withRenderingMode(.alwaysOriginal)
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.addSubview(cosmosView)
        let point = CGPoint(x: -130, y: -230)
        cosmosView.centerInSuperview(offset: point, priority: .defaultHigh, isActive: true, usingSafeArea: true)
        
        cosmosView.didFinishTouchingCosmos = { rating in
            print("Rated: \(rating)")
        }
        
        usernameLabel.text = (user?.firstName)! + " " + (user?.lastName)!
    }
    
    @IBAction func submitReview(_ sender: UIButton) {
        // add to Realtime database user/uid/reviews/posteruid/
        let ratingNumber = cosmosView.rating
        guard let postId = user?.safeEmail else { return }
        if let reviewText = textView.text {
            uploadReview(ratingNumber: ratingNumber, reviewText: reviewText, reviewedUid: postId)
        } else {
            uploadReview(ratingNumber: ratingNumber, reviewText: "", reviewedUid: postId)
        }
        
        // TODO : Segue to ReviewVC
        self.navigationController?.popViewController(animated: true)
    }
}

extension AddReviewVC {
    func uploadReview(ratingNumber: Double, reviewText: String, reviewedUid: String) {
        guard let uid = publicCurrentUser?.safeEmail else { return }
        ref = Database.database().reference()
        
        ref.child("users").child(reviewedUid).child("reviews").observeSingleEvent(of: .value, with: { (snapshot) in
            if let getData = snapshot.value as? [String:Any] {
                let reviewCount = (getData["numReviews"] as? Int)! + 1
                let newReview = self.ref.child("users").child(reviewedUid).child("reviews").child("review\(reviewCount)")
                newReview.child("userKey").setValue(uid)
                newReview.child("authorName").setValue("\(publicCurrentUser!.firstName!) \(publicCurrentUser!.lastName!)")
                newReview.child("location").setValue("\(publicCurrentUser!.city!), \(publicCurrentUser!.state!)")
                newReview.child("text").setValue(reviewText)
                newReview.child("timestamp").setValue([".sv": "timestamp"])
                newReview.child("rating").setValue(ratingNumber)
                self.ref.child("users").child(reviewedUid).child("reviews").child("numReviews").setValue(reviewCount)
            }
          }) { (error) in
            print(error.localizedDescription)
        }
    }
}
