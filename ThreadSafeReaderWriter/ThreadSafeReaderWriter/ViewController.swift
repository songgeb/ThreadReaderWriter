//
//  ViewController.swift
//  ThreadSafeReaderWriter
//
//  Created by songgeb on 2022/10/26.
//

import UIKit

class ViewController: UIViewController {

  var container: ThreadSafeContainer!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }

  private func testReadAndWrite() {
    var dict: [String: String] = [:]
    var begin = CACurrentMediaTime()
    var end = CACurrentMediaTime()
    dict["a"] = "1"
    dict.removeAll()
    let taskCount = 10
    let isReadingMode = false
    let queue = DispatchQueue(label: "serial")
    begin = CACurrentMediaTime()
    for _ in 0..<taskCount {
      queue.sync {
        if isReadingMode {
          _ = dict["a"]
        } else {
          dict["a"] = "1"
        }
      }
    }
    end = CACurrentMediaTime()
    print("单线程使用serialqueue\(isReadingMode ? "读" : "写") \(taskCount)次 耗时--\((end - begin) * 1000) ms")

    // clear
    dict.removeAll()

    var lock = pthread_rwlock_t()
    pthread_rwlock_init(&lock, nil)

    begin = CACurrentMediaTime()
    for _ in 0..<taskCount {
      if isReadingMode {
        pthread_rwlock_rdlock(&lock)
      } else {
        pthread_rwlock_wrlock(&lock)
      }
      if isReadingMode {
        _ = dict["a"]
      } else {
        dict["a"] = "1"
      }
      pthread_rwlock_unlock(&lock)
    }
    end = CACurrentMediaTime()
    print("单线程使用pthread_rwlock\(isReadingMode ? "读" : "写") \(taskCount)次 耗时--\((end - begin) * 1000) ms")
  }

  private func testAsyncReadWrite() {
    // 开两个线程，一个读，一个写，读1000次，写1000次
//    container = QueueThreadSafeContainer(qos: .default)
//    container = QueueThreadSafeContainer(qos: .userInitiated)
    container = QueueThreadSafeContainer(qos: .userInteractive)
//    container = LockThreadSafeContainer()
    let writerCount = 5
    let readerCount = 1
    let taskCount = 1000
    var writerArray: [Thread] = []
    var readerArray: [Thread] = []

    var begin = CACurrentMediaTime()
    var end = CACurrentMediaTime()

    for _ in 0..<writerCount {
      let writer = Thread {
        for i in 0..<taskCount {
          self.container.set(value: i, for: "\(i)") {
            end = CACurrentMediaTime()
            print("写耗时--\((end - begin) * 1000) ms")
          }
        }
      }
      writerArray.append(writer)
    }

    for _ in 0..<readerCount {
      let reader = Thread {
        for _ in 0..<taskCount {
          _ = self.container.data(by: "123")
          end = CACurrentMediaTime()
          print("读耗时--\((end - begin) * 1000) ms")
        }
      }
      readerArray.append(reader)
    }

    begin = CACurrentMediaTime()
    let allThreads = readerArray + writerArray
    for thread in allThreads {
      thread.start()
    }
  }
}

