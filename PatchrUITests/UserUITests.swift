//
//  PatchrUITests.swift
//  PatchrUITests
//
//  Created by Jay Massena on 1/12/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import XCTest

//@testable import Patchr	// Makes all internal api calls available

class UserUITests: BaseTestCase {
	
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAnonymous() {

		let guestButton = self.app.buttons["lobby_guest_button"]
		let profileTab = self.app.tabBars.buttons["profile_tab"]
		let nearbyButton = self.app.navigationBars["Nearby"].buttons["Nearby"]
		let watchingButton = self.app.navigationBars["Nearby"].buttons["Watching"]
		let ownButton = self.app.navigationBars["Nearby"].buttons["Own"]
		let exploreButton = self.app.navigationBars["Nearby"].buttons["Explore"]
		let mapButton = self.app.navigationBars["Nearby"].buttons["Map"]
		let addButton = self.app.navigationBars["Nearby"].buttons["Add"]
		let table = self.app.tables.elementBoundByIndex(0)
		let loginButton = self.app.buttons["login_login_button"]
		let guestLoginButton = self.app.buttons["guest_login_button"]
		let guestSignupButton = self.app.buttons["guest_signup_button"]
		let guestCancelButton = self.app.buttons["guest_cancel_button"]
		let navCancelButton = self.app.buttons["nav_cancel_button"]
		
		/* Handles it if it shows up */
		addUIInterruptionMonitorWithDescription("Location Dialog") {
			alert -> Bool in
			alert.buttons["Allow"].tap()
			return true
		}
		
		snapshot("LobbyScreen")
		
		guestButton.tap()
		waitForElementToExist(profileTab)
		
		XCTAssert(self.app.tables.count == 1)
		
		let complete = NSPredicate(format: "count > 0")
		expectationForPredicate(complete, evaluatedWithObject: table.cells, handler: nil)
		waitForExpectationsWithTimeout(5, handler: nil)
		
		/* These should be there */
		XCTAssert(nearbyButton.exists)
		XCTAssert(exploreButton.exists)
		XCTAssert(addButton.exists)
		XCTAssert(mapButton.exists)
		
		/* These should not be there */
		XCTAssert(!watchingButton.exists)
		XCTAssert(!ownButton.exists)
		
		snapshot("GuestNearbyScreen")
		
		/* Try to add a patch */
		addButton.tap()
		waitForElementToExist(guestLoginButton)
		
		/* Confirm that guest guard appeared */
		XCTAssert(guestCancelButton.exists)
		XCTAssert(guestLoginButton.exists)
		XCTAssert(guestSignupButton.exists)
		
		/* Exit guard */
		guestCancelButton.tap()
		waitForElementToExist(profileTab)
		
		/* Try to add a patch and then login */
		addButton.tap()
		waitForElementToExist(guestLoginButton)
		
		guestLoginButton.tap()
		waitForElementToExist(loginButton)
		navCancelButton.tap()
		
		/* Try to add a patch again and signup */
		addButton.tap()
		waitForElementToExist(guestLoginButton)
		
		guestSignupButton.tap()
		waitForElementToExist(loginButton)
		navCancelButton.tap()
    }
	
	func testSignupAndDelete() {
		
		/*--------------------------------------
		 * SIGNUP
		 --------------------------------------*/
		
		let signupButton = self.app.buttons["lobby_signup_button"]
		let navNextButton = self.app.buttons["nav_next_button"]
		let joinButton = self.app.buttons["join_button"]
		let emailField = self.app.textFields["email_field"]
		let passwordField = self.app.secureTextFields["password_field"]
		let nameField = self.app.textFields["name_field"]
		let setPhotoButton = self.app.buttons["photo_set_button"]
		let photoSearchButton = self.app.sheets.collectionViews.buttons["Search for photos"]
		let searchField = self.app.searchFields["Search for photos"]
		let searchButton = self.app.buttons["Search"]
		let usePhotoButton = self.app.toolbars.buttons["Use photo"]
		let loggedInToast = app.otherElements.elementMatchingPredicate(NSPredicate(format: "label BEGINSWITH 'Logged in as'"))
		let profileTab = self.app.tabBars.buttons["profile_tab"]
		let navEditButton = self.app.navigationBars["Me"].buttons["user_edit_button"]
		let navDeleteButton = self.app.navigationBars["Edit profile"].buttons["nav_delete_button"]
		let deleteConfirmAlert = self.app.alerts["Confirm account delete"]
		let lobbyLoginButton = self.app.buttons["lobby_login_button"]
		
		/* Go to email/password screen */
		signupButton.tap()
		
		waitForElementToExist(navNextButton)
		
		/* Set email and password */
		emailField.tapAndTypeText("superman@3meters.com")
		passwordField.tapAndTypeText("Patchme")
		
		/* Next page - email and password are passed as inputs */
		navNextButton.tap()
		
		waitForElementToExist(joinButton)
		
		nameField.tapAndTypeText("Superman")
		
		setPhotoButton.tap()
		photoSearchButton.tap()
		searchField.typeText("Superman")
		searchButton.tap()
		
		XCTAssert(self.app.collectionViews.count == 1)
		let collection = self.app.collectionViews.elementBoundByIndex(0)
		XCTAssert(collection.cells.count > 0)
		let cell = collection.cells.elementBoundByIndex(0)
		cell.forceTapElement()
		
		usePhotoButton.tap()
		
		waitForElementToExist(joinButton)
		
		joinButton.tap()
		
		waitForElementToExist(loggedInToast)
		
		/*--------------------------------------
		* DELETE USER
		--------------------------------------*/
		
		waitForElementToExist(profileTab)
		
		profileTab.forceTapElement()
		navEditButton.forceTapElement()
		navDeleteButton.tap()
		
		waitForElementToExist(deleteConfirmAlert)
		
		let confirmField = deleteConfirmAlert.textFields.elementBoundByIndex(0)
		confirmField.typeText("YES")
		deleteConfirmAlert.buttons["Delete"].tap()
		
		waitForElementToExist(lobbyLoginButton)
	}
	
	func testLoginLogout() {
		login(self)
		logout(self)
	}
	
	func testLoginBadPassword() {
		
		let lobbyLoginButton = self.app.buttons["lobby_login_button"]
		let loginButton = self.app.buttons["login_login_button"]
		let emailField = self.app.textFields["email_field"]
		let passwordField = self.app.secureTextFields["password_field"]
		let alert = self.app.alerts["Wrong email and password combination."]
		
		lobbyLoginButton.tap()
		waitForElementToExist(loginButton)
		
		/* Set wrong email */
		emailField.tapAndTypeText("batman@3meters.com")
		
		/* Set password */
		passwordField.tapAndTypeText("Batmanme")
		
		/* Try to login - should fail */
		loginButton.tap()
		
		waitForElementToExist(alert)
		
		alert.buttons["OK"].tap()
	}
	
	func testPasswordReset() {
		
		let lobbyLoginButton = self.app.buttons["lobby_login_button"]
		let loginButton = self.app.buttons["login_login_button"]
		let forgotButton = self.app.buttons["forgot_password_button"]
		let emailField = self.app.textFields["email_field"]
		let passwordField = self.app.secureTextFields["password_field"]
		let submitButton = self.app.buttons["submit_button"]
		let verifiedToast = self.app.otherElements.elementMatchingPredicate(NSPredicate(format: "label BEGINSWITH 'Email verified'"))
		
		lobbyLoginButton.tap()
		
		waitForElementToExist(loginButton)
		
		forgotButton.tap()
		
		waitForElementToExist(submitButton)
		
		emailField.tapAndTypeText("batman@3meters.com")
		submitButton.tap()
		
		waitForElementToExist(verifiedToast)
		
		passwordField.tapAndTypeText("Patchme")
		submitButton.tap()

		waitForElementToExist(loginButton)
	}
	
	func testPasswordChange() {
		
		let changePasswordButton = self.app.buttons["change_password_button"]
		let passwordField = self.app.secureTextFields["password_field"]
		let passwordNewField = self.app.secureTextFields["new_password_field"]
		let profileTab = self.app.tabBars.buttons["profile_tab"]
		let navSubmitButton = self.app.buttons["nav_submit_button"]
		let navCancelButton = self.app.buttons["nav_cancel_button"]
		let navEditButton = self.app.navigationBars["Me"].buttons["user_edit_button"]
		
		login(self)
		
		waitForElementToExist(profileTab)
		
		profileTab.forceTapElement()
		navEditButton.forceTapElement()
		changePasswordButton.tap()
		
		waitForElementToExist(passwordField)
		
		passwordField.tapAndTypeText("Patchme")
		passwordNewField.tapAndTypeText("Patchme")
		navSubmitButton.tap()
		
		waitForElementToExist(changePasswordButton)
		
		navCancelButton.tap()
		
		logout(self)
	}
	
	func testProfileEdit() {
		
		let profileTab = self.app.tabBars.buttons["profile_tab"]
		let navSubmitButton = self.app.buttons["nav_submit_button"]
		let navEditButton = self.app.navigationBars["Me"].buttons["user_edit_button"]
		let areaField = self.app.textFields["area_field"]
		let nameField = self.app.textFields["name_field"]
		
		login(self)
		
		waitForElementToExist(profileTab)
		
		profileTab.forceTapElement()
		navEditButton.forceTapElement()
		
		waitForElementToExist(navSubmitButton)
		
		nameField.tapAndTypeText("Mr. Batman")
		areaField.tapAndTypeText("Wayne Manor")
		
		navSubmitButton.tap()
		
		waitForElementToExist(profileTab) // We only return to profile if successful
		
		navEditButton.forceTapElement()
		
		waitForElementToExist(navSubmitButton)
		
		nameField.tapAndTypeText("Batman")
		areaField.tapAndTypeText(nil)	// Clears text
		
		navSubmitButton.tap()
		
		logout(self)
	}
	
	func testFacebookConnect() {
		
		let profileTab = self.app.tabBars.buttons["profile_tab"]
		let navSubmitButton = self.app.buttons["nav_submit_button"]
		let navEditButton = self.app.navigationBars["Me"].buttons["user_edit_button"]
		let facebookConnectButton = self.app.buttons["facebook_button"]
		
		login(self)
		
		waitForElementToExist(profileTab)
		
		profileTab.forceTapElement()
		navEditButton.forceTapElement()
		
		waitForElementToExist(navSubmitButton)
		
		facebookConnectButton.tap()		// Connect
	}
}
