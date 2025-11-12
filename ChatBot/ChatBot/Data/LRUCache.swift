//
//  LRUCache.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/11/25.
//

import Foundation

nonisolated final class LRUCache<Key: Hashable, Value: Any> {
    
    private var hashMap = [Key:Node]()
    private var linkedList = LinkedList()
    var capacity: Int
    
    init(capacity: Int = 2) {
        self.capacity = capacity
    }
    
    func getValue(_ key: Key) -> Value? {
        if let node = hashMap[key] {
            linkedList.moveToFront(node: node)
            return node.value
        }
        return nil
    }
    
    func setValue(_ value: Value, key: Key) {
        if let node = hashMap[key] {
            node.value = value
            linkedList.moveToFront(node: node)
            return
        }
        let requiresEviction = hashMap.count >= capacity
        let node = Node(key: key, value: value)
        linkedList.add(node: node)
        hashMap[key] = node
        if requiresEviction {
            if let node = linkedList.removeLast() {
                hashMap[node.key] = nil
            }
        }
    }
    
    func removeValueFor(key: Key) {
        if let node = hashMap[key] {
            linkedList.remove(node: node)
            hashMap[node.key] = nil
        }        
    }
    
    func printHashMap() {
        print("------- Hashmap -------")
        for item in hashMap {
            print("key \(item.key) value \(item.value.value)")
        }
        print("------- LinkedList -------")
        linkedList.printList()
    }
    
    private final class Node {
        var value: Value
        var key: Key
        var next: Node?
        var prev: Node?
        
        init(key: Key, value: Value) {
            self.value = value
            self.key = key
        }
    }
    
    private final class LinkedList {
        
        private var head:Node?
        private var tail: Node?
        
        func add(node: Node) {
            if head == nil {
                head = node
                tail = node
                return
            }
            node.next = head
            head?.prev = node
            head = node
        }
        
        func remove(node: Node) {
            if node === head {
                let next = head?.next
                head = next
                next?.prev = nil
                if head == nil {
                    tail = nil
                }
            }else if node === tail {
                let prev = tail?.prev
                tail = prev
                prev?.next = nil
            }else {
                let prev = node.prev
                prev?.next = node.next
                node.next?.prev = prev
                node.prev = nil
                node.next = nil
            }
            
        }
        
        func removeLast() -> Node? {
            guard let last = tail else {
                return nil
            }
            remove(node: last)
            return last
        }
        
        func moveToFront(node: Node) {
            remove(node: node)
            add(node: node)
        }
        
        func printList() {
            var node = head
            while node != nil {
                if let node {
                    print("linkedlist key \(node.key) value \(node.value)")
                }
                node = node?.next
            }
        }
    }
}
