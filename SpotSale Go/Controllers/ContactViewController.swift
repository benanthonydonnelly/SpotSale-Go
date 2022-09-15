//
//  SheetViewController.swift
//  SpotSale Go
//
//  Created by Ben-Anthony Donnelly on 04/09/2022.
//

import Foundation
import UIKit
import Contacts

protocol ContactViewControllerDelegate {
    func didDismissSheet()
}

class ContactViewController:UIViewController {
    var delegate:ContactViewControllerDelegate?
    var contact:CNContact = CNContact()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        
        let containerView = UIView(frame: CGRect(x: 15, y: 45, width: view.frame.width - 30, height: view.frame.height - 55))
        view.addSubview(containerView)
        
        let vStackView = UIStackView()
        vStackView.axis = .vertical
        vStackView.alignment = .fill
        vStackView.distribution = .fill
        vStackView.translatesAutoresizingMaskIntoConstraints = false
        vStackView.spacing = 10
        containerView.addSubview(vStackView)
        
        let hstackView = UIStackView()
        hstackView.axis = .horizontal
        hstackView.translatesAutoresizingMaskIntoConstraints = false
        hstackView.spacing = 10
        vStackView.addArrangedSubview(hstackView)
        
        if contact.imageDataAvailable, let data = contact.imageData {
            let imageView = UIImageView()
            imageView.image = UIImage(data: data)
            imageView.contentMode = .scaleAspectFill
            imageView.layer.masksToBounds = true
            imageView.layer.cornerRadius = 35
            imageView.layer.borderColor = CGColor.init(red: 1, green: 1, blue: 1, alpha: 1)
            imageView.layer.borderWidth = 4
            hstackView.addArrangedSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 70),
                imageView.heightAnchor.constraint(equalToConstant: 70),
            ])
        }
        
        let nameLabel = UILabel(frame: CGRect(x: 15, y: 0, width: view.frame.size.width - 30, height: 100))
        nameLabel.font = .boldSystemFont(ofSize: 25)
        nameLabel.text = "\(contact.givenName) \(contact.familyName)"
        hstackView.addArrangedSubview(nameLabel)
        
        if let phoneView = getPhoneView(forView: containerView) {
            vStackView.addArrangedSubview(phoneView)
        }
        
        let notesView = getNotesView(forView: containerView)
        vStackView.addArrangedSubview(notesView)
    }
    
    func getNotesView(forView:UIView) -> UIView {
        let notesView = UIView()
        
        let noteTitle = UILabel(frame: CGRect(x: 0, y: 0, width: forView.frame.width, height: 40))
        noteTitle.text = "Notes"
        noteTitle.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        notesView.addSubview(noteTitle)
        
        let notesTextView = UITextView(frame: CGRect(x: 0, y: 40, width: forView.frame.width, height: 360))
//        notesTextView.text = contact.note
        notesTextView.text = "notes go here"
        notesView.addSubview(notesTextView)
        
        NSLayoutConstraint.activate([
            notesView.widthAnchor.constraint(equalToConstant: forView.frame.width),
            notesView.heightAnchor.constraint(equalToConstant: 400),
        ])
        
        return notesView
    }
    
    func getPhoneView(forView:UIView) -> UIView? {
        guard let number = (contact.phoneNumbers.first?.value as? CNPhoneNumber)?.stringValue else {return nil}
        
        let phoneView = UIView()
        phoneView.layer.setValue(number, forKey: "phone_number")
        
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "phone.fill")

        let attribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .regular)]
        let fullString = NSMutableAttributedString(string: " ", attributes: attribute)
        fullString.append(NSAttributedString(attachment: imageAttachment))
        fullString.append(NSAttributedString(string: " " + number))
        
        let phoneNumberLabel = UILabel(frame: CGRect(x: 0, y: 0, width: forView.frame.width, height: 30))
        phoneNumberLabel.attributedText = fullString
        phoneNumberLabel.isUserInteractionEnabled = false
        phoneView.addSubview(phoneNumberLabel)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(phone(sender:)))
        phoneView.addGestureRecognizer(tap)
        
        NSLayoutConstraint.activate([
            phoneView.widthAnchor.constraint(equalToConstant: forView.frame.width),
            phoneView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return phoneView
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.delegate?.didDismissSheet()
    }
}


// MARK: Actions

extension ContactViewController {
    @objc func phone(sender:UITapGestureRecognizer) {
        guard let number = sender.view?.layer.value(forKey: "phone_number") else {return}
        
        if let url = URL(string: "tel://\(number)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
