//
//  TaskListView.swift
//  ProcrastDonate
//
//  Created by Andrew Morgan on 24/02/2021.
//

import SwiftUI
import SwiftBSON

struct TaskListView: View {
    @EnvironmentObject var state: AppState
    
    @State private var tasks = [Task]()
    @State private var showingNewTaskSheet = false
    @State var newTask = Task()
    
    var body: some View {
        List {
            ForEach(tasks) { task in
                TaskCard(task: task, action: sort)
            }
        }
        .onAppear(perform: loadTasks)
        .sheet(isPresented: $showingNewTaskSheet) {
            TaskDetailsView(task: newTask)
        }
        .onChange(of: showingNewTaskSheet, perform: { value in
            if !value {
                saveTask()
            }
        })
        .navigationBarTitle("ProcrastDonate Tasks", displayMode: .inline)
        .navigationBarItems(
            leading: Button(action: loadTasks) {
                Image(systemName: "arrow.clockwise.circle.fill")
            },
            trailing: Button(action: { showingNewTaskSheet = true }) {
                Image(systemName: "plus.circle.fill")
                    .renderingMode(.original)
        })
    }
    
    func loadTasks() {
        if state.localMode {
            tasks = Task.samples
            sort()
        } else {
            let address =
                "\(state.APIURL)users/\(User.sample._id.description)/tasks?sort-by=earliest-deadline&date-delimiter=2000-10-05T14:48:00Z"
            guard let url = URL(string: address) else {
                print("Invalid URL")
                return
            }
            let request = URLRequest(url: url)
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let data = data {
                    if let decodedResponse = try? ExtendedJSONDecoder().decode([Task].self, from: data) {
                        DispatchQueue.main.async {
                            self.tasks = decodedResponse
                            sort()
                        }
                        return
                    }
                }
                print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            }.resume()
        }
    }
    
    func sort() {
        tasks.sort { left, right in
            if left.completed != right.completed {
                return right.completed
            }
            if left.completed {
                return left.completedDate ?? left.deadlineDate > right.completedDate ?? left.deadlineDate
            }
            return left.deadlineDate < right.deadlineDate
        }
    }
    
    func saveTask() {
        // TODO: Remove once we have user management
        newTask.user = User.sample._id
        newTask.charity = Charity.sample._id
        if state.localMode {
            tasks.append(newTask)
        } else {
            tasks.append(newTask)
            
            guard let encoded = try? ExtendedJSONEncoder().encode(newTask) else {
                print("Failed to encode new task")
                return
            }
            guard let url = URL(string: "\(state.APIURL)users/\(newTask.user.description)/tasks") else {
                print("Failed to encode URL")
                return
            }
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = encoded
            URLSession.shared.dataTask(with: request) { data, _, error in
                if data == nil {
                    print("No data in response: \(error?.localizedDescription ?? "Unknown error").")
                } else {
                    print("New task sent")
                }
            }.resume()
        }
        newTask = Task()
        sort()
    }
}

struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskListView()
                .environmentObject(AppState())
        }
    }
}
