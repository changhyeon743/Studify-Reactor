//
//  HomeReactor.swift
//  Studify
//
//  Created by 이창현 on 04/08/2019.
//  Copyright © 2019 이창현. All rights reserved.
//

import Foundation
import ReactorKit
import RxSwift
import SwiftyJSON

final class HomeReactor: Reactor {
    enum Action {
        case phoneReversed
        case currentChanged(String)
    }
    
    enum Mutation {
        case setReversed(Bool)
        case setCurrent(String)
        case showAmount(Int)
    }
    
    struct State {
        var current: String
        var reversed: Bool //true일 경우 엎어져있을 때
    }
    
    let initialState = State(current: "공부 선택", reversed: false)
    
    
    func mutate(action: HomeReactor.Action) -> Observable<HomeReactor.Mutation> {
        switch action {
        case .phoneReversed:
            //Network
            let reversed = !currentState.reversed
            return Observable.concat([
                Observable.just(Mutation.setReversed(reversed)),
                (reversed) ?
                    start(token: "S1eqBxAcYiymiEFSInNTbyPvjdSgbRMY", current: currentState.current)
                        .map{Mutation.showAmount($0)} :
                    stop(token: "S1eqBxAcYiymiEFSInNTbyPvjdSgbRMY")
                        .map{Mutation.showAmount($0)}
                ])
        case let .currentChanged(newCurrent):
            return Observable.just(Mutation.setCurrent(newCurrent))
        }
    }
    
    func reduce(state: HomeReactor.State, mutation: HomeReactor.Mutation) -> HomeReactor.State {
        switch mutation {
        case let .setReversed(reversed):
            return State(current: state.current, reversed: !reversed)
        case let .setCurrent(newCurrent):
            return State(current: newCurrent, reversed: state.reversed)
        case let .showAmount(amount):
            print(amount)
            return currentState
        }
    }
}

extension HomeReactor {
    
    private func start(token: String,current: String) -> Observable<Int> {
        guard let url = URL(string: baseURL+"/user/start") else {return .just(0)}
        // prepare json data
        let json: [String: Any] = ["token": token,
                                   "current": current]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        return URLSession.shared.rx.json(request: request)
            .map { json -> (Int) in
                let data = JSON(json)
                return data["amount"].intValue
            }
            .do(onError: { error in
                print(error.localizedDescription)
            })
            .catchErrorJustReturn(0)
    }
    
    private func stop(token: String) -> Observable<Int> {
        guard let url = URL(string: baseURL+"/user/end") else {return .just(0)}
        // prepare json data
        
        let jsonData = try? JSONSerialization.data(withJSONObject: ["token": token])
        
        // create post request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        return URLSession.shared.rx.json(request: request)
            .map { json -> (Int) in
                let data = JSON(json)
                return data["amount"].intValue
            }
            .do(onError: { error in
                print(error.localizedDescription)
            })
            .catchErrorJustReturn(0)
    }
}
