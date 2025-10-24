//
//  ChatCollectionViewController.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/17/25.
//
import Foundation
import Combine
import UIKit

typealias DataSource = UICollectionViewDiffableDataSource<Int, ChatCollectionViewDataItem>

final class ChatCollectionViewController: UIViewController {
    
    private var collectionView: UICollectionView?
    private var chats: [ChatCollectionViewDataItem] = []
    private var viewModel: ChatCollectionViewModelProtocol
    var dataSource: DataSource?
    var cancellables: Set<AnyCancellable> = []
    
    var lastIndexPath: IndexPath {
        IndexPath(row: chats.count - 1, section: 0)
    }
    
    init(viewModel: ChatCollectionViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let collectionViewLayout = ChatCollectionFlowLayout(viewModel: viewModel)
        
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        collectionView?.translatesAutoresizingMaskIntoConstraints = false
        collectionView?.delegate = self
        
        collectionView?.backgroundColor = .lightText
        collectionView?.showsVerticalScrollIndicator = false
        guard let collectionView else { return }
        collectionView.register(ChatMessageViewCollectionViewCell.self, forCellWithReuseIdentifier: "chat")
        collectionView.register(ChatDateViewCollectionViewCell.self, forCellWithReuseIdentifier: "date")

        dataSource = UICollectionViewDiffableDataSource<Int, ChatCollectionViewDataItem>(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            
            switch item {
                case let item as ChatDataModel:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "chat", for: indexPath) as? ChatMessageViewCollectionViewCell else {
                        return UICollectionViewCell()
                    }
                    cell.setup(chat: item)
                    return cell
                case let item as DateDataModel:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "date", for: indexPath) as? ChatDateViewCollectionViewCell else {
                        return UICollectionViewCell()
                    }
                    cell.setup(chat: item)
                    return cell
                default:
                    return UICollectionViewCell()
            }
        })
        self.view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        self.viewModel.chatsPublisher
            .receive(on: RunLoop.main)
            .sink {[weak self] (chats, type) in
                self?.reloadChats(chats: chats, type: type)
            }.store(in: &cancellables)
        
//        viewModel.fetchChats()        
    }
    
    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ChatCollectionViewDataItem>()
        snapshot.appendSections([0])
        snapshot.appendItems(chats)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    
    func reloadChats(chats: [ChatCollectionViewDataItem], type: ChatsUpdateType) {
                
        self.chats = chats
        Task {@MainActor in
            applySnapshot()
            
            if type == .appended {
                collectionView?.scrollToItem(at: lastIndexPath, at: .top, animated: true)
            }
        }
    }
        
    func fetchOldChats() {
        viewModel.fetchChats()
    }
}

extension ChatCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard (collectionView.isTracking || collectionView.isDecelerating)  &&  indexPath.row < 3 else {return}
//        fetchOldChats()
    }
}

