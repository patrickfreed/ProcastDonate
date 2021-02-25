import MongoDBVapor
import Vapor

/// Controller for /tasks/<taskid> route.
internal enum Tasks {
    struct PaymentDetails: Codable {
        let title: String
        let user: User
        let sponsorships: [SponsorshipPaymentDetails]
        let charity: Charity
        let donationAmount: MonetaryValue
        let donateOnFailure: Bool
    }

    struct SponsorshipPaymentDetails: Codable {
        let _id: BSONObjectID
        let sponsor: User
        let donationAmount: MonetaryValue
    }

    /// PATCH handler.
    /// Used to update the status of a task.
    static func patch(taskID: BSONObjectID, req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let update = try req.content.decode(TaskUpdateRequest.self)

        switch update {
        case .markAsCompleted:
            let filter = Task.queryFilter(forID: taskID, isActive: true)
            let update: BSONDocument = [
                "$set": ["completedDate": .datetime(Date())],
            ]
            return req.tasks.updateOne(filter: filter, update: update).flatMapThrowing { result -> Void in
                // no such active task
                guard let result = result else {
                    throw Abort(.notFound)
                }
                // this task was already marked as done
                guard result.modifiedCount == 1 else {
                    throw Abort(.alreadyReported)
                }
            }.flatMap { _ in
                // find active sponsorships
                let filter: BSONDocument = ["task": .objectID(taskID), "cancelledDate": ["$exists": false]]
                return req.sponsorships.updateMany(filter: filter, update: ["$set": ["settled": true]])
            }.flatMap { (_: UpdateResult?) in
                let pipeline: [BSONDocument] = [
                    ["$match": ["_id": .objectID(taskID)]],
                    [
                        "$lookup": [
                            "from": "user",
                            "localField": "user",
                            "foreignField": "_id",
                            "as": "user",
                        ],
                    ],
                    ["$unwind": "$user"],
                    [
                        "$lookup": [
                            "from": "charity",
                            "localField": "charity",
                            "foreignField": "_id",
                            "as": "charity",
                        ],
                    ],
                    ["$unwind": "$charity"],
                    [
                        "$lookup": [
                            "from": "sponsorship",
                            "pipeline": [
                                ["$match": .document(Sponsorship.queryFilter(forTask: taskID, isActive: true))],
                                [
                                    "$lookup": [
                                        "from": "user",
                                        "localField": "sponsor",
                                        "foreignField": "_id",
                                        "as": "sponsor",
                                    ],
                                ],
                                ["$unwind": "$sponsor"],
                            ],
                            "as": "sponsorships",
                        ],
                    ],
                    [
                        "$project": [
                            "title": 1,
                            "user": 1,
                            "sponsorships": 1,
                            "charity": 1,
                            "donationAmount": 1,
                            "donateOnFailure": 1,
                        ],
                    ],
                ]

                return req.tasks.aggregate(pipeline, withOutputType: PaymentDetails.self).flatMap { cursor in
                    cursor.toArray().map { $0.first }.unwrap(or: Abort(.notFound))
                }
            }.flatMap { (paymentInfo: PaymentDetails) in
                // if donateOnFailure is true, then there's nothing to do here
                // because the task succeeeded
                guard !paymentInfo.donateOnFailure else {
                    req.logger.info("\"\(paymentInfo.title)\" completed. donateOnFailure=true so no payments necessary")
                    return req.eventLoop.makeSucceededVoidFuture()
                }

                req.logger.info("Processing payments for \"\(paymentInfo.title)\"")
                var futures = [EventLoopFuture<Void>]()
                let taskDonation = Payment.processDonation(
                    req,
                    to: paymentInfo.charity,
                    by: paymentInfo.user,
                    amount: paymentInfo.donationAmount
                )
                futures.append(taskDonation)

                for sponsorship in paymentInfo.sponsorships {
                    let payment = Payment.processDonation(
                        req,
                        to: paymentInfo.charity,
                        by: sponsorship.sponsor,
                        amount: sponsorship.donationAmount
                    )
                    futures.append(payment)
                }

                return EventLoopFuture.andAllSucceed(futures, on: req.eventLoop).map {
                    req.logger.info("payments processed successfully")
                }
            }.map { (_: Void) in
                HTTPStatus.ok
            }
        }
    }
}
