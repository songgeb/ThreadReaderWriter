//
//  ThreadSafeIO.swift
//  Test-Swift
//
//  Created by songgeb on 2022/10/25.
//  Copyright © 2022 songgeb.test. All rights reserved.
//

import Foundation

protocol ThreadSafeContainer {
  /// 同步读
  func data(by key: String) -> Any?
  /// 异步写
  func set(value: Any, for key: String, completion: @escaping () -> Void)
}

/// 多读单写
class QueueThreadSafeContainer: ThreadSafeContainer {
  private var data: [String: Any] = [:]
  private let queue: DispatchQueue
  deinit {
    print("释放")
  }
  init(qos: DispatchQoS = .default) {
    queue = DispatchQueue(
      label: "com.QueueThreadSafeContainer",
      qos: qos,
      attributes: .concurrent,
      autoreleaseFrequency: .workItem,
      target: nil)
  }

  func set(value: Any, for key: String, completion: @escaping () -> Void) {
    queue.async(flags: .barrier) {
      self.data[key] = value
      completion()
    }
  }

  func data(by key: String) -> Any? {
    return queue.sync {
      return self.data[key]
    }
  }
}

class LockThreadSafeContainer: ThreadSafeContainer {
  private var data: [String: Any] = [:]
  private var lock = pthread_rwlock_t()

  init() {
    pthread_rwlock_init(&lock, nil)
  }

  deinit {
    pthread_rwlock_destroy(&lock)
    print("释放")
  }

  func data(by key: String) -> Any? {
    var value: Any?
    pthread_rwlock_rdlock(&lock)
    value = data[key]
    pthread_rwlock_unlock(&lock)
    return value
  }

  func set(value: Any, for key: String, completion: @escaping () -> Void) {
    pthread_rwlock_wrlock(&lock)
    data[key] = value
    pthread_rwlock_unlock(&lock)
    completion()
  }
}
