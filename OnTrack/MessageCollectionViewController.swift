//
//  MessageCollectionViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 2/8/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import RealmSwift

class MessageCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    
    fileprivate let cellId = "cellId"
    var messages = [Message]()
    var timer: Timer!
    var bottomConstraint: NSLayoutConstraint?
    var reload = false
    var driver: RealmDriver!
    let realm = try! Realm()
    var driverId: Int!
    var driverName: String!
    var isGroup = false
    var groupId: Int?

    let messageInputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = navBarColor
        return view
    }()
    
    let inputTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Type a message...",
                                                            attributes: [NSAttributedStringKey.foregroundColor: UIColor.lightGray])
        textField.textColor = .white
        return textField
    }()
    
    lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: UIControlState())
        let titleColor = UIColor(red: 76/255, green: 160/255, blue: 255/255, alpha: 1)
        button.setTitleColor(titleColor, for: UIControlState())
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        //button.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //print(driver)
        //print(driverName)
        
        //let d = realm.objects(RealmDriver.self).first
        //driver = d!
        
        //Test if not needed
        //let m = Message(body: "")
        //messages.append(m)
        
        inputTextField.delegate = self
        
        collectionView?.frame = CGRect(x: 0, y: 60, width: view.frame.width, height: view.frame.height - 115)
        
        let navBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.layer.frame.width, height: 62))
        navBar.barTintColor = UIColor(red: 41/255, green: 50/255, blue: 65/255, alpha: 1.0)
        navBar.isTranslucent = false
        navBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        self.view.addSubview(navBar)
        //let navItem = UINavigationItem(title: driver.name)
        //let doneItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: nil, action: #selector(dismissVC))
        //navItem.rightBarButtonItem = doneItem
        //navBar.setItems([navItem], animated: false)
        
        /*
        APIManager.shared.getMessages(driver.id) { (messages) in
            self.messages = messages
            
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                if self.messages.count > 0 {
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: false)
                }
            }
        }
        */
        
        collectionView?.backgroundColor = UIColor.black
        collectionView?.register(ChatLogMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        view.addSubview(messageInputContainerView)
        view.addConstraintsWithFormat("H:|[v0]|", views: messageInputContainerView)
        view.addConstraintsWithFormat("V:[v0(48)]", views: messageInputContainerView)
        
        bottomConstraint = NSLayoutConstraint(item: messageInputContainerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraint(bottomConstraint!)
        
        setupInputComponents()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        if isGroup == true {
            let navItem = UINavigationItem(title: "Group Text")
            let doneItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: nil, action: #selector(dismissVC))
            navItem.rightBarButtonItem = doneItem
            navBar.setItems([navItem], animated: false)
            sendButton.addTarget(self, action: #selector(sendGroupMessage), for: .touchUpInside)
            if let id = groupId {
                getGroupMessages(groupId: id)
            }
        } else {
            let navItem = UINavigationItem(title: driver.name)
            let doneItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: nil, action: #selector(dismissVC))
            //let driverItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: nil, action: #selector(dismissVC))
            //navItem.leftBarButtonItem = doneItem
            navItem.rightBarButtonItem = doneItem
            navBar.setItems([navItem], animated: false)
            getMessages()
            sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
            timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(getMessages), userInfo: nil, repeats: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isGroup == false {
            timer.invalidate()
            //let last = messages.last as! Message
            //print("last----------------- \(last.id)")
            //updateMessage(id: last.id)
        } else {
            
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        collectionView?.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func dismissVC() {
        dismiss(animated: true, completion: nil)
    }
    
    //GET `/api/v1/events/:event_id/message_groups/:id: `
    //3) API to send a message to a message group
    //POST `/api/v1/events/:event_id/message_groups/:id/send_message`
    
    func getGroupMessages(groupId: Int) {
        let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event_id)/message_groups/\(groupId)"
        print(path)
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(path, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                let jsonMessages = json["data"]["messages"].arrayValue
                //print(jsonMessages)
                self.messages.removeAll()
                
                for message in jsonMessages {
                    let m = Message(body: message["body"].stringValue)
                    self.messages.append(m)
                }
                
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
                
            case .failure:
                break
            }
        }

    }
    
    func updateMessage(id: Int) {
        let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event_id)/messages/\(id)/mark_read"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        print(path)
        
        Alamofire.request(path, method: .put, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            print(response)
            
            switch response.result {
            case .success(let jsonObject):
                let json = JSON(jsonObject)
                print(json)
            case .failure:
                break
            }
        }
    }

    
    @objc func sendGroupMessage() {
        if let message = inputTextField.text {
            
            let m = Message(body: message)
            
            messages.append(m)
            
            if let id = groupId {
                let path = "\(BASE_URL)/api/v1/events/\(currentUser!.event!.eventId)/message_groups/\(id)/send_message"
                print(path)
                
                let headers = [
                    "Content-Type": "application/json"
                ]
                
                let parameters = [
                    "message":
                    ["event_id": currentUser!.event!.eventId,
                    "body": message]
                ] as [String : Any]
                
                Alamofire.request(path, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    switch response.result {
                    case .success(let jsonObject):
                        let json = JSON(jsonObject)
                        print(json)
                        
                        DispatchQueue.main.async {
                            //self.tableView.reloadData()
                        }
                        
                    case .failure:
                        break
                    }
                }
            }
            
            let item = messages.count - 1
            
            let insertionIndexPath = IndexPath(item: item, section: 0)
            
            collectionView?.insertItems(at: [insertionIndexPath])
            collectionView?.scrollToItem(at: insertionIndexPath, at: .bottom, animated: true)
            
            //collectionView?.reloadData()
            inputTextField.text = nil
        }
    }

    @objc func getMessages() {
        APIManager.shared.getMessages(driver.id) { (messages) in
            self.messages = messages
            
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                if self.messages.count > 0 {
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: false)
                }
            }
        }
    }

    @objc func handleSend() {
        
        if let message = inputTextField.text {
            
            let m = Message(body: message)
        
            messages.append(m)
            
            APIManager.shared.postMessage(body: m.body, phoneNumber: driver.cell!, eventId: (driver.event?.eventId)!, routeId: (driver.route?.id)!)
            
            let item = messages.count - 1
            
            let insertionIndexPath = IndexPath(item: item, section: 0)
            
            collectionView?.insertItems(at: [insertionIndexPath])
            collectionView?.scrollToItem(at: insertionIndexPath, at: .bottom, animated: true)
            
            //collectionView?.reloadData()
            inputTextField.text = nil
            
        }
    }
    
    @objc func handleKeyboardNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
            //print(keyboardFrame)
            
            let isKeyboardShowing = notification.name == NSNotification.Name.UIKeyboardWillShow
            
            bottomConstraint?.constant = isKeyboardShowing ? -keyboardFrame!.height : 0
            
            UIView.animate(withDuration: 0, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                
                self.view.layoutIfNeeded()
                
            }, completion: { (completed) in
                
                if isKeyboardShowing {
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    //self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
                
                
            })
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        inputTextField.endEditing(true)
    }
    
    fileprivate func setupInputComponents() {
        let topBorderView = UIView()
        topBorderView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        
        messageInputContainerView.addSubview(inputTextField)
        messageInputContainerView.addSubview(sendButton)
        messageInputContainerView.addSubview(topBorderView)
        
        messageInputContainerView.addConstraintsWithFormat("H:|-8-[v0][v1(60)]|", views: inputTextField, sendButton)
        
        messageInputContainerView.addConstraintsWithFormat("V:|[v0]|", views: inputTextField)
        messageInputContainerView.addConstraintsWithFormat("V:|[v0]|", views: sendButton)
        
        messageInputContainerView.addConstraintsWithFormat("H:|[v0]|", views: topBorderView)
        messageInputContainerView.addConstraintsWithFormat("V:|[v0(0.5)]", views: topBorderView)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatLogMessageCell
        
        cell.messageTextView.text = messages[indexPath.item].body
        
        let message = messages[indexPath.item]
            
            cell.profileImageView.image = UIImage(named: "user")
        
            let size = CGSize(width: 250, height: 1000)
            let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
            let estimatedFrame = NSString(string: message.body).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18)], context: nil)
        
            if message.isSender == false {
                cell.messageTextView.frame = CGRect(x: 48 + 8, y: 0, width: estimatedFrame.width + 16, height: estimatedFrame.height + 20)
                
                cell.textBubbleView.frame = CGRect(x: 48 - 10, y: -4, width: estimatedFrame.width + 16 + 8 + 16, height: estimatedFrame.height + 20 + 6)
                
                cell.profileImageView.isHidden = false
                //cell.profileImageView.image = UIImage(named: "user")
                
                //                cell.textBubbleView.backgroundColor = UIColor(white: 0.95, alpha: 1)
                cell.bubbleImageView.image = ChatLogMessageCell.grayBubbleImage
                cell.bubbleImageView.tintColor = UIColor(red: 31/255, green: 37/255, blue: 51/255, alpha: 0.88)
                cell.messageTextView.textColor = UIColor.white
                
            } else {
                
                //outgoing sending message
                
            cell.messageTextView.frame = CGRect(x: view.frame.width - estimatedFrame.width - 16 - 16 - 8, y: 0, width: estimatedFrame.width + 16, height: estimatedFrame.height + 20)
                
                cell.textBubbleView.frame = CGRect(x: view.frame.width - estimatedFrame.width - 16 - 8 - 16 - 10, y: -4, width: estimatedFrame.width + 16 + 8 + 10, height: estimatedFrame.height + 20 + 6)
                
                cell.profileImageView.isHidden = true
                
                //                cell.textBubbleView.backgroundColor = UIColor(red: 0, green: 137/255, blue: 249/255, alpha: 1)
                cell.bubbleImageView.image = ChatLogMessageCell.blueBubbleImage
                cell.bubbleImageView.tintColor = UIColor(red: 76/255, green: 160/255, blue: 255/255, alpha: 1)
                cell.messageTextView.textColor = UIColor.white
            }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let messageText = messages[indexPath.item].body
        let size = CGSize(width: 250, height: 1000)
            let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
            let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18)], context: nil)
            
            return CGSize(width: view.frame.width, height: estimatedFrame.height + 20)
        
        
        //return CGSize(width: view.frame.width, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(8, 0, 0, 0)
    }
}
