//
//  FirebaseRxExtensions.swift
//  RxFireSwift-Database
//
//  Created by Morten Bek Ditlevsen on 30/09/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import FirebaseFirestore
import FireSwift_Database
import Foundation
import RxSwift

extension DecodeResult {
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

enum Sko: Error {
    case ski
}

func convert<T>(decoder: StructureDecoder, snap: DocumentSnapshot?, error: Error?) -> DecodeResult<T> where T: Decodable {
    if let snap = snap {
        if let data = snap.data() {
            do {
                let blah = try decoder.decode(T.self, from: data)
                return DecodeResult(value: blah)
            } catch {
                return DecodeResult(error: DecodeError.conversionError(error))
            }
        } else {
            return DecodeResult(error: DecodeError.noValuePresent)
        }

    } else if let error = error {
        return DecodeResult(error: DecodeError.internalError(error))
    } else {
        return DecodeResult(error: DecodeError.internalError(Sko.ski))
    }

}

func convert<T>(decoder: StructureDecoder, snap: QuerySnapshot?, error: Error?) -> DecodeResult<[String: T]> where T: Decodable {
    if let snap = snap {
        if snap.isEmpty {
            return DecodeResult(error: DecodeError.noValuePresent)
        } else {
            let hund = Dictionary(uniqueKeysWithValues: snap.documents.map { ($0.documentID, $0.data()) })
            do {
                let blah = try decoder.decode([String: T].self, from: hund)
                return DecodeResult(value: blah)
            } catch {
                return DecodeResult(error: DecodeError.conversionError(error))
            }
        }
    } else if let error = error {
        return DecodeResult(error: DecodeError.internalError(error))
    } else {
        return DecodeResult(error: DecodeError.internalError(Sko.ski))
    }
}

/**
 Convenience extensions for `DatabaseQuery` (and thus also `DatabaseReference`)
 */
extension Reactive where Base: DocumentReference {
    /**
     Creates a `Single` representing the asynchronous fetch of a value from the Realtime Database

     - Parameter type: The `DataEventType` to listen for.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: A `Single` of the requested generic type.
     */
    public func observeSingleEvent<T>(using decoder: StructureDecoder = .init()) -> Single<T>
        where T: Decodable {
        return Single.create { single in
            self.base.getDocument(completion: { (snap, error) in
                single(convert(decoder: decoder, snap: snap, error: error).asSingleEvent)
            })
            return Disposables.create()
        }
    }

    /**
     Creates an `Observable` representing the stream of changes to a value from the Realtime Database

     - Parameter type: The `DataEventType` to listen for.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: An `Observable` of the requested generic type wrapped in a `DecodeResult`.
     */
    public func observe<T>(using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<T>>
        where T: Decodable {
        return Observable.create { observer in
            let registration = self.base.addSnapshotListener({ (snap, error) in
                observer.onNext(convert(decoder: decoder, snap: snap, error: error))
            })
            return Disposables.create {
                registration.remove()
            }
        }
    }
}

/**
 Convenience extensions for `DatabaseQuery` (and thus also `DatabaseReference`)
 */
extension Reactive where Base: CollectionReference {
    /**
     Creates a `Single` representing the asynchronous fetch of a value from the Realtime Database

     - Parameter type: The `DataEventType` to listen for.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: A `Single` of the requested generic type.
     */
    public func observeSingleEvent<T>(using decoder: StructureDecoder = .init()) -> Single<[String: T]>
        where T: Decodable {
            return Single.create { single in
                self.base.getDocuments(completion: { (snap, error) in
                    single(convert(decoder: decoder, snap: snap, error: error).asSingleEvent)
                })
                return Disposables.create()
            }
    }

    /**
     Creates an `Observable` representing the stream of changes to a value from the Realtime Database

     - Parameter type: The `DataEventType` to listen for.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: An `Observable` of the requested generic type wrapped in a `DecodeResult`.
     */
    public func observe<T>(using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<[String: T]>>
        where T: Decodable {
            return Observable.create { observer in
                let registration = self.base.addSnapshotListener({ (snap, error) in
                    observer.onNext(convert(decoder: decoder, snap: snap, error: error))
                })
                return Disposables.create {
                    registration.remove()
                }
            }
    }

    // TODO WIP XXX something with .added / .removed / .changed...
    public func observeChanges<T>(using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<T>>
        where T: Decodable {
            return Observable.create { observer in
                let registration = self.base.addSnapshotListener({ (snap, error) in
                    for change in snap?.documentChanges ?? [] {
                        let sko = change.document
                        do {
                            let ska = try decoder.decode(T.self, from: sko.data())
                            observer.onNext(.success(ska))
                        } catch {
                            observer.onNext(.failure(DecodeError.conversionError(error)))
                        }
                    }
//                    observer.onNext(convert(decoder: decoder, snap: snap, error: error))
                })
                return Disposables.create {
                    registration.remove()
                }
            }
    }

}


/**
 Convenience extensions for `Database`
 */
extension Reactive where Base: Firestore {

    /**
     Creates a `Single` representing the asynchronous fetch of a value from the Realtime Database

     - Parameter path: The path to the value in the Realtime Database hierarchy.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: A `Single` of the generic type matching that of the supplied `path` parameter.
     */
    public func observeSingleEvent<T>(at path: Path<T>,
                               using decoder: StructureDecoder = .init()) -> Single<T>
        where T: Decodable {
            return self.base.document(path.rendered).rx.observeSingleEvent()
    }

    /**
     Creates an `Observable` representing the stream of changes to a value from the Realtime Database

     - Parameter path: The path to the value in the Realtime Database hierarchy.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: An `Observable` of the generic type matching that of the supplied `path` parameter, wrapped in a `DecodeResult`.
     */
    public func observe<T>(at path: Path<T>,
                    using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<T>>
        where T: Decodable {
            return self.base.document(path.rendered).rx.observe()
    }

    /**
     Creates a `Single` representing the asynchronous fetch of a value from the Realtime Database

     - Parameter eventType: The `CollectionEventType` to listen for.

     - Parameter path: The path to a collection of values in the Realtime Database hierarchy.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: A `Single` of the generic type matching that of the supplied collection `path` parameter.
     */
    public func observeSingleEvent<T>(at path: Path<T>.Collection,
                                      using decoder: StructureDecoder = .init()) -> Single<[String: T]>
        where T: Decodable {
            return self.base.collection(path.rendered).rx.observeSingleEvent()
    }

    /**
     Creates an `Observable` representing the stream of changes to a value from the Realtime Database

     - Parameter eventType: The `CollectionEventType` to listen for.

     - Parameter path: The path to a collection of values in the Realtime Database hierarchy.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: An `Observable` of the generic type matching that of the supplied collection `path` parameter, wrapped in a `DecodeResult`.
     */
    public func observe<T>(at path: Path<T>.Collection,
                           using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<[String: T]>>
        where T: Decodable {
            return self.base.collection(path.rendered).rx.observe()
    }
}
