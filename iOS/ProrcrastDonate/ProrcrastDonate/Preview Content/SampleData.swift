//
//  SampleData.swift
//  ProrcrastDonate
//
//  Created by Andrew Morgan on 23/02/2021.
//

import Foundation
import SwiftBSON

protocol Samplable {
    associatedtype Item
    static var sample: Item { get }
    static var samples: [Item] { get }
}

extension Date {
    static var random: Date {
        Date(timeIntervalSince1970: (50 * 365 * 24 * 3600 + Double.random(in: 0..<(3600 * 24 * 365))))
    }
}

extension User {
    convenience init(_ user: User) {
        self.init()
        // Don't copy _id
        userName = user.userName
        displayName = user.displayName
        email = user.email
        password = user.password
        bio = user.bio
        friends.append(contentsOf: user.friends)
    }
}

extension User: Samplable {
    static var samples: [User] { [sample, sample2, sample3] }
    static var sample: User {
        try! User(
            _id: BSONObjectID("f0d456789012345678901234"),
            userName: "rod",
            displayName: "Rod",
            email: "rod@contoso.com",
            password: "rainbow",
            bio: "Singer from Rod, Jane and Freddy",
            friends: [sample2._id, sample3._id])
    }
    static var sample2: User {
        try! User(
            _id: BSONObjectID("1ade56789012345678901234"),
            userName: "jane",
            displayName: "Jane",
            email: "jane@contoso.com",
            password: "rainbow",
            bio: "The best singer from Rod, Jane and Freddy",
            friends: [sample._id, sample3._id])
    }
    static var sample3: User {
        try! User(
            _id: BSONObjectID("ffedde789012345678901234"),
            userName: "freddy",
            displayName: "Freddy",
            email: "freddy@contoso.com",
            password: "rainbow",
            bio: "The other singer from Rod, Jane and Freddy",
            friends: [sample._id, sample2._id])
    }
}

extension Renewal {
    convenience init(_ renewal: Renewal) {
        self.init()
        date = renewal.date
        oldDeadline = renewal.oldDeadline
        newDeadline = renewal.newDeadline
        oldAmount = renewal.oldAmount
        newAmount = renewal.newAmount
        renewReason = renewal.renewReason
        paidOldAmount = renewal.paidOldAmount
    }
}

extension Renewal: Samplable {
    static var samples: [Renewal] { [sample, sample2, sample3] }
    static var sample: Renewal {
        Renewal(
            date: Date(),
            oldDeadline: Date(),
            newDeadline: Date().addingTimeInterval(86400),
            oldAmount: 10,
            newAmount: 15,
            renewReason: "Being lazy",
            paidOldAmount: true)
    }
    static var sample2: Renewal {
        Renewal(
            date: Date(),
            oldDeadline: Date().addingTimeInterval(-86400),
            newDeadline: Date().addingTimeInterval(86400),
            oldAmount: 5,
            newAmount: 10,
            renewReason: "Being super lazy",
            paidOldAmount: false)
    }
    static var sample3: Renewal {
        Renewal(
            date: Date().addingTimeInterval(-46340),
            oldDeadline: Date().addingTimeInterval(-400),
            newDeadline: Date().addingTimeInterval(166400),
            oldAmount: 5,
            newAmount: 0,
            renewReason: "Being super-super lazy",
            paidOldAmount: false)
    }
}

extension Charity {
    convenience init (_ charity: Charity) {
        self.init()
        _id = charity._id
        name = charity.name
        descriptionText = charity.descriptionText
        website = charity.website
    }
}

extension Charity: Samplable {
    static var samples: [Charity] { [sample, sample2, sample3] }
    static var sample: Charity {
        try! Charity(
            _id: BSONObjectID("cad456789012345678901234"),
            name: "Save The Cats",
            descriptionText: "Looking after the furry little critters",
            website: "https://clusterdb.com")
    }
    static var sample2: Charity {
        try! Charity(
            _id: BSONObjectID("bad456789012345678901234"),
            name: "Save The Bats",
            descriptionText: "Blocking planning applications for years",
            website: "https://clusterdb.com")
    }
    static var sample3: Charity {
        try! Charity(
            _id: BSONObjectID("1ab456789012345678901234"),
            name: "Save The Tabs",
            descriptionText: "Spaces are for the birds",
            website: "https://clusterdb.com")
    }
}

extension Task {
    convenience init(_ task: Task) {
        self.init()
        // Don't copy _id
        title = task.title
        descriptionText = task.descriptionText
        startDate = task.startDate
        completedDate = task.completedDate
        cancelDate = task.cancelDate
        for renewal in task.renewals {
            renewals.append(Renewal(renewal))
        }
        deadlineDate = task.deadlineDate
        donateOnFailure = task.donateOnFailure
        donationAmount = task.donationAmount
        charity = task.charity
        tags.append(contentsOf: task.tags)
    }
}

extension Task: Samplable {
    static var samples: [Task] { [sample, sample2, sample3] }
    static var sample: Task {
        try! Task(
            _id: BSONObjectID("111456789012345678901234"),
            title: "Task 1",
            descriptionText: """
            This is the first task's description.
            It can scan many lines.
            many...
            many...
            many...
            """,
            startDate: Date(),
            cancelDate: nil,
            renewals: Renewal.samples,
            deadlineDate: Date().addingTimeInterval(86400),
            donateOnFailure: true,
            donationAmount: 25,
            charity: Charity.sample._id,
            tags: ["animals"])
    }
    static var sample2: Task {
        try! Task(
            _id: BSONObjectID("222456789012345678901234"),
            title: "Task 2",
            descriptionText: "Second task",
            startDate: Date(),
            cancelDate: nil,
            renewals: Renewal.samples,
            deadlineDate: Date().addingTimeInterval(226400),
            donateOnFailure: false,
            donationAmount: 0,
            tags: ["animals", "creepy"])
    }
    static var sample3: Task {
        try! Task(
            _id: BSONObjectID("333456789012345678901234"),
            title: "Task 3 - with a longer task name than some others",
            descriptionText: "Third task - which has a longer description than some others. Filler text here. Filler text here. ",
            startDate: Date().addingTimeInterval(-86400),
            completedDate: Date().addingTimeInterval(-16400),
            cancelDate: Date(),
            renewals: [],
            deadlineDate: Date().addingTimeInterval(126400),
            donateOnFailure: true,
            donationAmount: 10,
            charity: Charity.sample3._id,
            tags: ["developers"])
    }
}
