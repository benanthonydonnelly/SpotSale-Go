//
//  ContactManager.swift
//  SpotSale Go
//
//  Created by Ben-Anthony Donnelly on 10/09/2022.
//

import Foundation
import Contacts

class ContactManager {
    let cmQueue = DispatchQueue(label: "cmQueue")
    let contactStore = CNContactStore()
    func getContacts(_ completion: @escaping ([CNContact]) -> Void) {
        var contacts:[CNContact] = []
        contactStore.requestAccess(for: .contacts) { success, error in
            guard success else {print(error ?? "request contacts access failed"); return}
            
            let keysToFetch = [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactPostalAddressesKey,
                CNContactEmailAddressesKey,
                CNContactPhoneNumbersKey
            ]
            let fetchRequest = CNContactFetchRequest( keysToFetch: keysToFetch as [CNKeyDescriptor])
            
            self.cmQueue.async {
                do {
                    try CNContactStore().enumerateContacts(with: fetchRequest) { (contact, stop) -> Void in
                        //do something with contact
                        if contact.givenName.count > 0 {
                            contacts.append(contact)
                        }
                    }
                } catch let e as NSError {
                    print(e.localizedDescription)
                }
                completion(contacts)
            }
        }
    }
    
    func getContact(identifier:String) -> CNContact? {
        let predicate = CNContact.predicateForContacts(withIdentifiers: [identifier])
        let keysToFetch = [
            CNContactImageDataAvailableKey,
            CNContactImageDataKey,
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPostalAddressesKey,
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey
        ]
        
        do {
            let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch as [CNKeyDescriptor])
            guard contacts.count > 0 else {return nil}
            return contacts[0]
        } catch {}
        return nil
    }
}
