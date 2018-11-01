//
//  FirebaseRxExtensions.swift
//  RxFireSwift-Firestore
//
//  Created by Morten Bek Ditlevsen on 30/09/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import FirebaseFirestore
import FireSwift_DecodeResult
import FireSwift_Firestore
import FireSwift_Paths
import FireSwift_StructureCoding
import Foundation
import Result
import RxSwift

private extension DecodeResult {
    // A small convenience to re-wrap a `DecodeResult` as a `SingleEvent`
    var asSingleEvent: SingleEvent<Value> {
        switch self {
        case .success(let v):
            return .success(v)
        case .failure(let e):
            return .error(e)
        }
    }
}

/**
 Convenience extensions for `DocumentReference`
 */
extension Reactive where Base: DocumentReference {
    /**
     Creates a `Single` representing the asynchronous fetch of a document from Firestore

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: A `Single` of the requested generic type.
     */
    public func observeSingleEvent<T>(using decoder: StructureDecoder = .init()) -> Single<T>
        where T: Decodable {
        return Single.create { single in
            self.base.observeSingleEvent(using: decoder, with: { result in
                single(result.asSingleEvent)
            })
            return Disposables.create()
        }
    }

    /**
     Creates an `Observable` representing the stream of changes to a document from Firestore

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: An `Observable` of the requested generic type wrapped in a `DecodeResult`.
     */
    public func observe<T>(using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<T>>
        where T: Decodable {
        return Observable.create { observer in
            let registration = self.base.observe(with: { result in
                observer.onNext(result)
            })
            return Disposables.create {
                registration.remove()
            }
        }
    }
}

/**
 Convenience extensions for `CollectionReference`
 */
extension Reactive where Base: CollectionReference {
    /**
     Creates a `Single` representing the asynchronous fetch of an array of values from the Firestore collection

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: A `Single` of the requested generic type.
     */
    public func observeSingleEvent<T>(using decoder: StructureDecoder = .init()) -> Single<[T]>
        where T: Decodable {
            return Single.create { single in
                self.base.observeSingleEvent(using: decoder, with: { result in
                    single(result.asSingleEvent)
                })
                return Disposables.create()
            }
    }

    /**
     Creates an `Observable` representing the stream of changes to an array of values from Firestore

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: An `Observable` of the requested generic type wrapped in a `DecodeResult`.
     */
    public func observe<T>(using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<[T]>>
        where T: Decodable {
            return Observable.create { observer in
                let registration = self.base.observe { result in
                    observer.onNext(result)
                }
                return Disposables.create {
                    registration.remove()
                }
            }
    }
}

//public struct Change<T> {
//    let type: DocumentChangeType
//    let value: T
//
//    init(type: DocumentChangeType, value: T) {
//        self.type = type
//        self.value = value
//    }
//}

//    Experimentation!
//extension Reactive where Base: CollectionReference {
//    public func observeChanges<T>(using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<Change<T>>>
//        where T: Decodable {
//            return Observable.create { observer in
//                let registration = self.base.addSnapshotListener(wrap { result in
//                    switch result {
//                    case .success(let snap):
//                        for change: DocumentChange in snap.documentChanges {
//                            do {
//                                let ska = try decoder.decode(T.self, from: change.document.data())
//                                let res = Change(type: change.type, value: ska)
//                                observer.onNext(.success(res))
//                            } catch {
//                                observer.onNext(.failure(DecodeError.conversionError(error)))
//                            }
//                        }
//
//                    case .failure(let error):
//                        observer.onNext(.failure(DecodeError.conversionError(error.error)))
//                    }
//                })
//                return Disposables.create {
//                    registration.remove()
//                }
//            }
//    }


/**
 Convenience extensions for `Firestore`
 */
extension Reactive where Base: Firestore {

    /**
     Creates a `Single` representing the asynchronous fetch of a document from Firestore

     - Parameter path: The path to the value in the Firestore hierarchy.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: A `Single` of the generic type matching that of the supplied `path` parameter.
     */
    public func observeSingleEvent<T>(at path: Path<T>,
                               using decoder: StructureDecoder = .init()) -> Single<T>
        where T: Decodable {
            return self.base.document(path.rendered).rx.observeSingleEvent()
    }

    /**
     Creates an `Observable` representing the stream of changes to a document from Firestore

     - Parameter path: The path to the value in the Firestore hierarchy.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: An `Observable` of the generic type matching that of the supplied `path` parameter, wrapped in a `DecodeResult`.
     */
    public func observe<T>(at path: Path<T>,
                    using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<T>>
        where T: Decodable {
            return self.base.document(path.rendered).rx.observe()
    }

    /**
     Creates a `Single` representing the asynchronous fetch of an array of values from the Firestore collection

     - Parameter path: The path to a collection of values in the Firestore hierarchy.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: A `Single` of the generic type matching that of the supplied collection `path` parameter.
     */
    public func observeSingleEvent<T>(at path: Path<T>.Collection,
                                      using decoder: StructureDecoder = .init()) -> Single<[T]>
        where T: Decodable {
            return self.base.collection(path.rendered).rx.observeSingleEvent()
    }

    /**
     Creates an `Observable` representing the stream of changes to an array of values from the Firestore collection

     - Parameter path: The path to a collection of values in the Firestore hierarchy.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: An `Observable` of the generic type matching that of the supplied collection `path` parameter, wrapped in a `DecodeResult`.
     */
    public func observe<T>(at path: Path<T>.Collection,
                           using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<[T]>>
        where T: Decodable {
            return self.base.collection(path.rendered).rx.observe()
    }
}
