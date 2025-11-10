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
        collectionView.register(ChatSystemMessageViewCollectionViewCell.self, forCellWithReuseIdentifier: "systemMessage")
        
        // Diffable data source to reflect changes
        dataSource = UICollectionViewDiffableDataSource<Int, ChatCollectionViewDataItem>(collectionView: collectionView, cellProvider: {[weak self] collectionView, indexPath, item in
            
            switch item {
                case let item as ChatDataModel:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "chat", for: indexPath) as? ChatMessageViewCollectionViewCell else {
                        return UICollectionViewCell()
                    }
                    let tapAction: (()->Void) = {[weak self] in
                        self?.viewModel.showCharts(item: item)
                    }
                    cell.setup(chat: item, action: tapAction)
                    return cell
                case let item as DateDataModel:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "date", for: indexPath) as? ChatDateViewCollectionViewCell else {
                        return UICollectionViewCell()
                    }
                    cell.setup(chat: item)
                    return cell
                case let item as ChatSystemMessageDataModel:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "systemMessage", for: indexPath) as? ChatSystemMessageViewCollectionViewCell else {
                        return UICollectionViewCell()
                    }
                    var buttonAction: (()->Void)?
                    if let action = item.retryableAction {
                        buttonAction = {
                            self?.viewModel.retryAction(action)
                        }
                    }
                    cell.setup(chat: item, action: buttonAction)
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

        // Start listening to chats update
        self.viewModel.chatsPublisher
            .receive(on: RunLoop.main)
            .sink {[weak self] (chats, type) in
                self?.reloadChats(chats: chats, type: type)
            }.store(in: &cancellables)
        
        // Fetch any existing old chats
        viewModel.fetchChats()
    }
    
    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ChatCollectionViewDataItem>()
        snapshot.appendSections([0])
        snapshot.appendItems(chats)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    // Called when we get any updates
    func reloadChats(chats: [ChatCollectionViewDataItem], type: ChatsUpdateType) {
                
        self.chats = chats
        Task {@MainActor in
            applySnapshot()
            
            // when added to the bottom we need to make sure to scroll to bring the last chat in visible range
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
        // TODO: find a better way to handle this
        // TODO: used if we want tp paginate old chats
//        fetchOldChats()
    }
}

