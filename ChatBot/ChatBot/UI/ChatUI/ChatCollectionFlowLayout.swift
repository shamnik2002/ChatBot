//
//  ChatCollectionFlowLayout.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/17/25.
//
import Foundation
import UIKit
import Combine

final class ChatCollectionFlowLayout : UICollectionViewFlowLayout {
    
    private var attributeList = [UICollectionViewLayoutAttributes]()
    private var chats: [ChatCollectionViewDataItem] = []
    private var cancellables = Set<AnyCancellable>()
    private var collectionViewHeight: CGFloat = 0
    
    struct Constants {
        static let leftPadding: CGFloat = 10
        static let userChatLeftPadding: CGFloat = 75 // change it to percentage later
        static let rightPadding: CGFloat = 10
        static let interimSpacing: CGFloat = 15
    }
    init(viewModel: ChatCollectionViewModelProtocol) {
        super.init()
        viewModel.chatsPublisher
            .receive(on: RunLoop.main)
            .sink {[weak self] (chats, type) in
                self?.chats = chats
            }.store(in: &cancellables)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        
        guard let collectionView, !self.chats.isEmpty else {return}
        
        var yOffset: CGFloat = 0

        //assumption only 1 section
        let rows = collectionView.numberOfItems(inSection: 0)
        attributeList.removeAll()

        guard self.chats.count == rows else {return}
        for row in 0..<rows {
            let chat = chats[row]
            
            switch chat {
                case let chat as ChatDataModel:
                    let attributes = getAttributesForChatDataModel(chat, collectionView: collectionView, row: row, yOffset: yOffset)
                    yOffset += attributes.frame.height + Constants.interimSpacing
                    attributeList.append(attributes)
               
                case let chat as DateDataModel:
                    let attributes = getAttributesForDateDataModel(chat, collectionView: collectionView, row: row, yOffset: yOffset)
                    yOffset += attributes.frame.height + Constants.interimSpacing
                    attributeList.append(attributes)

                case let chat as ChatSystemMessageDataModel:
                    let attributes = getAttributesForSystemMessageDataModel(chat, collectionView: collectionView, row: row, yOffset: yOffset)
                    yOffset += attributes.frame.height + Constants.interimSpacing
                    attributeList.append(attributes)

                default:
                    break
            }
            
        }
        collectionViewHeight = yOffset
    }
    
    func getAttributesForChatDataModel(_ chatDataModel: ChatDataModel, collectionView: UICollectionView, row: Int, yOffset: CGFloat) -> UICollectionViewLayoutAttributes {
        
        let attributedText = NSAttributedString(
            string: chatDataModel.text,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle:.headline),
                .foregroundColor: UIColor.systemBlue,
                .kern: 1.2
            ]
        )
        let topBottomPadding = ChatMessageView.Constants.topPadding + ChatMessageView.Constants.bottomPadding
        let leftPadding = chatDataModel.type == .user ? Constants.userChatLeftPadding : Constants.leftPadding
        let xOffset: CGFloat = leftPadding
        let width = collectionView.bounds.width - leftPadding - Constants.rightPadding

        let height = attributedText.height(constrainedToWidth: collectionView.frame.width) + topBottomPadding
        let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: row, section: 0))
        attributes.frame = CGRect(x: xOffset, y: yOffset, width: width, height: height)
        return attributes
    }
    
    func getAttributesForDateDataModel(_ dateDataModel: DateDataModel, collectionView: UICollectionView, row: Int, yOffset: CGFloat) -> UICollectionViewLayoutAttributes {
        
        let attributedText = NSAttributedString(
            string: Date(timeIntervalSince1970: dateDataModel.date).shortRelativeDate(),
            attributes: [
                .font: UIFont.preferredFont(forTextStyle:.headline),
                .foregroundColor: UIColor.systemBlue,
                .kern: 1.2
            ]
        )
        
        let topBottomPadding = ChatDateView.Constants.topPadding + ChatDateView.Constants.bottomPadding
        let height = ceil(attributedText.height(constrainedToWidth: collectionView.frame.width) + topBottomPadding)

        let leftPadding = Constants.leftPadding
        let xOffset: CGFloat = leftPadding
        let width = collectionView.bounds.width - leftPadding - Constants.rightPadding

        let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: row, section: 0))
        attributes.frame = CGRect(x: xOffset, y: yOffset, width: width, height: height)
        return attributes
    }
    
    func getAttributesForSystemMessageDataModel(_ dateDataModel: ChatSystemMessageDataModel, collectionView: UICollectionView, row: Int, yOffset: CGFloat) -> UICollectionViewLayoutAttributes {
        
        let attributedText = NSAttributedString(
            string: "Trending...",
            attributes: [
                .font: UIFont.preferredFont(forTextStyle:.headline),
                .foregroundColor: UIColor.systemBlue,
                .kern: 1.2
            ]
        )
        
        let topBottomPadding = ChatDateView.Constants.topPadding + ChatDateView.Constants.bottomPadding
        let height = ceil(attributedText.height(constrainedToWidth: collectionView.frame.width) + topBottomPadding)

        let leftPadding = Constants.leftPadding
        let xOffset: CGFloat = leftPadding
        let width = collectionView.bounds.width - leftPadding - Constants.rightPadding

        let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: row, section: 0))
        attributes.frame = CGRect(x: xOffset, y: yOffset, width: width, height: height)
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = [UICollectionViewLayoutAttributes]()
        for attr in attributeList {
            if rect.intersects(attr.frame) {
                attributes.append(attr)
            }
        }
            return attributes
        }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard self.attributeList.count > indexPath.row else {return nil}
        return attributeList[indexPath.row]
    }
    
    override var collectionViewContentSize: CGSize {
        let width = collectionView?.bounds.width ?? 0
        return CGSize(width: width, height: collectionViewHeight)
    }
}

extension NSAttributedString {
    func height(constrainedToWidth width: CGFloat) -> CGFloat {
        let size = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(boundingBox.height)
    }
}
