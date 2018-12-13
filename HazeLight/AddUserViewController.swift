//
//  AddUserViewController.swift
//  HazeLight
//
//  Created by Jon Shier on 9/13/18.
//  Copyright © 2018 Jon Shier. All rights reserved.
//

import UIKit

final class AddUserViewController: UIViewController {
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var tokenTextField: UITextField!
    
    private let logicController = AddUserLogicController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logicController.observe { print($0) }
    }
    
    @IBAction func addUser() {
        guard let email = emailTextField.text, let token = tokenTextField.text else { return }
        
        logicController.addUser(email: email, token: token)
    }
    
    @IBAction func editUser(_ sender: UIButton) {
        logicController.editUser()
    }
}

final class AddUserLogicController: ObservableLogicController<AddUserLogicController.State> {
    struct State {
        let isLoading: Bool
    }
    
    private let users: UsersModelController
    
    init(users: UsersModelController = .shared) {
        self.users = users
        
        super.init(state: .init(isLoading: false))
        
        addObservations { [weak self] in
            [users.pendingCredential.observe { self?.state = State(isLoading: ($0 != nil)) }]
        }
    }
    
    func addUser(email: String, token: String) {
        users.addUser(email: email, token: token)
    }
    
    func editUser() {
        users.editCurrentUser(zipCode: "48421")
    }
}

class ObservableLogicController<State>: Observable {
    var state: State {
        didSet {
            observer?(state)
        }
    }
    
    private var observer: Observation?
    private var tokens: [NotificationToken] = []
    
    init(state: State) {
        self.state = state
    }
    
    func observe(returningCurrentValue: Bool = true,
                 queue: OperationQueue = .main,
                 handler: @escaping (State) -> Void) {
        observer = { state in
            queue.addOperation { handler(state) }
        }
        
        if returningCurrentValue {
            observer?(state)
        }
    }
    
    func addObservations(_ observations: () -> [NotificationToken]) {
        self.tokens += observations()
    }
}

// Validation of UI input
// Encapsulate LogicController observation
// Break strong reference cycle.
// Include debug origination information for observations.

class ClosureObservable<State> {
    private var state: State? {
        didSet { state.map { listener?($0) } }
    }
    private var listener: ((State) -> Void)?
    
    func listen(listener: @escaping (State) -> Void) {
        self.listener = listener
        state.map(listener)
    }
    
    func updateState(_ state: State) {
        self.state = state
    }
}
