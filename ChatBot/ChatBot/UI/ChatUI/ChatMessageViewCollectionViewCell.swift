//
//  ChatViewCollectionViewCell.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/17/25.
//

import SwiftUI
import Combine
import UIKit

final class ChatMessageViewCollectionViewCell: UICollectionViewCell {
    
    
    private var hostingController: UIHostingController<ChatMessageView>?
    override init(frame: CGRect) {

        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
          super.prepareForReuse()
      }
    
    func setup(chat: ChatDataModel) {
        
        let viewModel = ChatMessageViewModel(chatDataModel: chat)
        guard hostingController == nil else {
            hostingController?.rootView.viewModel = viewModel
            return
        }
        
        let chatViewCell = ChatMessageView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: chatViewCell)
        self.hostingController = hostingController
        self.hostingController?.view.backgroundColor = .clear
        contentView.addSubview(hostingController.view)
        contentView.backgroundColor = .clear
        self.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }        
}


final class ChatDateViewCollectionViewCell: UICollectionViewCell {    
    
    private var hostingController: UIHostingController<ChatDateView>?
    override init(frame: CGRect) {

        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
          super.prepareForReuse()
      }
    
    func setup(chat: DateDataModel) {
        
        let viewModel = ChatDateViewModel(dateDataModel: chat)
        guard hostingController == nil else {
            hostingController?.rootView.viewModel = viewModel
            return
        }
        
        let chatViewCell = ChatDateView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: chatViewCell)
        self.hostingController = hostingController
        self.hostingController?.view.backgroundColor = .clear
        contentView.addSubview(hostingController.view)
        contentView.backgroundColor = .clear
        self.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

final class ChatSystemMessageViewCollectionViewCell: UICollectionViewCell {
    
    private var hostingController: UIHostingController<ChatSystemMessageView>?
    override init(frame: CGRect) {

        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
          super.prepareForReuse()
      }
    
    func setup(chat: ChatSystemMessageDataModel) {
        
        let viewModel = ChatSystemMessageViewModel(texts: chat.texts)
        guard hostingController == nil else {
            hostingController?.rootView.viewModel = viewModel
            return
        }
        
        let chatViewCell = ChatSystemMessageView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: chatViewCell)
        self.hostingController = hostingController
        self.hostingController?.view.backgroundColor = .clear
        contentView.addSubview(hostingController.view)
        contentView.backgroundColor = .clear
        self.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
