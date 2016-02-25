//
//  Created by Jay Massena on 1/12/16.
//  Copyright © 2016 3meters. All rights reserved.
//

struct Field {
    static let Email                = "email_field"
    static let Password             = "password_field"
    static let NewPassword          = "new_password_field"
    static let Name                 = "name_field"
    static let Area                 = "area_field"
    static let Search               = "search_field"
    static let ResetEmail           = "reset_email_field"
    static let ResetPassword        = "reset_password_field"
    static let ConfirmDelete        = "confirm_delete_field"
}

struct Toast {
	static let EmailVerified        = "Email verified"
	static let LoggedIn             = "Logged in as"
	static let PasswordReset		= "Password reset"
	static let PasswordChanged		= "Password changed"
}

struct Alert {
	static let BadEmailPassword     = "Wrong email and password combination."
	static let ConfirmDelete        = "Confirm account delete"
	static let InvalidEmail			= "Enter a valid email address."
	static let InvalidNewPassword   = "Enter a new password with six characters or more."
	static let InvalidPassword		= "Enter a password with six characters or more."
	static let ResetEmailNotUsed	= "This email address has not been used with this installation. Please contact support to reset your password."
	static let ResetEmailNotFound	= "The email address could not be found."
	static let ResetEmailEmpty		= "Enter an email address you have used before on this device."
}

struct Button {
    static let ForgotPassword       = "forgot_password_button"
    static let ChangePassword       = "change_password_button"
    static let Submit               = "submit_button"
    static let Guest                = "guest_button"
    static let Signup               = "signup_button"
    static let Login                = "login_button"
    static let Cancel               = "cancel_button"
    static let Logout               = "logout_button"
    static let PhotoSet             = "photo_set_button"
    static let Search               = "Search"
    static let UsePhoto             = "Use photo"
    static let Facebook             = "facebook_button"
	
	static let ClearHistory         = "clear_history_button"
	static let Notifications		= "notifications_button"
	static let SendFeedback			= "send_feedback_button"
	static let RateApp				= "rate_app_button"
	static let TermsOfService		= "terms_of_service_button"
	static let PrivacyPolicy		= "privacy_policy_button"
	static let Licensing			= "licensing_button"
}

struct Switch {
	static let NofificationNearby	= "notification_nearby_switch"
	static let NofificationMessage	= "notification_message_switch"
	static let NofificationShare	= "notification_share_switch"
	static let NofificationLike		= "notification_like_switch"
	static let SoundNofification	= "sound_notification_switch"
	static let SoundEffects			= "sound_effects_switch"
}

struct Sheet {
    static let PhotoSearch          = "Search for photos"
    static let PhotoLibraby         = "Search for photos"
    static let Camera               = "Search for photos"
}

struct Map {
    static let Patch                = "patch_map"
    static let Patches              = "patches_map"
}

struct Table {
    static let Patches              = "patches_table"
    static let Users                = "users_table"
    static let Messages             = "messages_table"
    static let Notifications        = "notifications_table"
    static let Search               = "search_table"
	static let Settings				= "settings_table"
}

struct Collection {
    static let Photos               = "photo_collection"
}

struct View {
    static let Lobby                = "lobby_view"
	static let Guest                = "guest_view"
    static let Login                = "login_view"
    static let SignupLogin          = "signup_login_view"
    static let SignupProfile        = "signup_profile_view"
    static let PasswordEdit         = "password_edit_view"
    static let PasswordReset        = "password_reset_view"
    static let ProfileEdit          = "profile_edit_view"
	
	static let TermsOfService		= "terms_of_service_view"
	static let PrivacyPolicy		= "privacy_policy_view"
	static let Licensing			= "licensing_view"
	static let Feedback				= "feedback_view"
	static let Report				= "report_view"
	
    static let PatchEdit            = "patch_edit_view"
    static let MessageEdit          = "message_edit_view"
    static let Settings             = "settings_view"
	static let WebBrowser			= "web_browser_view"
    static let NotificationSettings = "notification_settings_view"
    static let Invite               = "invite_view"
    static let Main                 = "main_view"
    static let MessageDetail        = "message_detail_view"
    static let PatchDetail          = "patch_detail_view"
    static let UserDetail           = "user_detail_view"
    static let PatchMap             = "patch_map_view"
    static let PatchesMap           = "patches_map_view"
    static let Search               = "search_view"
    static let Notifications        = "nofications_view"
    static let Users                = "users_view"
    static let PhotoSearch          = "photo_search_view"
    static let Development          = "development_view"
    static let Invitation           = "invitation_view"
    static let TextZoom             = "text_zoom_view"
    static let Patches              = "patches_view"
    static let PatchesNearby        = "patches_nearby_view"
    static let PatchesWatching      = "patches_watching_view"
    static let PatchesOwn           = "patches_own_view"
    static let PatchesExplore       = "patches_explore_view"
}

struct AlertButton {
    static let Delete               = "Delete"
    static let Ok                   = "OK"
}

struct Tab {
    static let Patches              = "tab_patches"
    static let Notifications        = "tab_notifications"
    static let Search               = "tab_search"
    static let Profile              = "tab_profile"
}

struct Segment {
    static let Nearby               = "Nearby"
    static let Watching             = "Groups"
    static let Own                  = "Own"
    static let Explore              = "Explore"
}

struct Nav {
    static let MapLabel             = "Map"
    static let AddLabel             = "Add"
	static let MeLabel				= "Me"
	static let SettingsLabel		= "Settings"
    static let Cancel               = "nav_cancel_button"
    static let Next                 = "nav_next_button"
    static let Delete               = "nav_delete_button"
    static let Submit               = "nav_submit_button"
    static let Edit                 = "nav_edit_button"
    static let Settings             = "nav_settings_button"
}