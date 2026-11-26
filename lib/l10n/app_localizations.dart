import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Lazim'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Everything the home needs, in one place.'**
  String get appTagline;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Lazim'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One shared list for everything your home needs. No more digging through chats.'**
  String get signInSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get continueWithEmail;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameLabel;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Lazim?'**
  String get signOutConfirm;

  /// No description provided for @demoModeBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo mode — data stays on this device'**
  String get demoModeBanner;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @familySetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your home'**
  String get familySetupTitle;

  /// No description provided for @familySetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a family group, or join one with an invite code.'**
  String get familySetupSubtitle;

  /// No description provided for @createFamily.
  ///
  /// In en, this message translates to:
  /// **'Create a family'**
  String get createFamily;

  /// No description provided for @joinFamily.
  ///
  /// In en, this message translates to:
  /// **'Join a family'**
  String get joinFamily;

  /// No description provided for @familyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get familyNameLabel;

  /// No description provided for @familyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Home, Al-Sayed family'**
  String get familyNameHint;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeLabel;

  /// No description provided for @inviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'LAZIM-XXXXXX'**
  String get inviteCodeHint;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @joining.
  ///
  /// In en, this message translates to:
  /// **'Joining…'**
  String get joining;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get creating;

  /// No description provided for @inviteNotFound.
  ///
  /// In en, this message translates to:
  /// **'That invite code doesn\'t exist. Check it and try again.'**
  String get inviteNotFound;

  /// No description provided for @needsTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs'**
  String get needsTitle;

  /// No description provided for @needsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing needed right now'**
  String get needsEmptyTitle;

  /// No description provided for @needsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add the first thing your home needs. Groceries, medicine, a light bulb — anything.'**
  String get needsEmptyBody;

  /// No description provided for @addNeed.
  ///
  /// In en, this message translates to:
  /// **'Add a need'**
  String get addNeed;

  /// No description provided for @addFirstNeed.
  ///
  /// In en, this message translates to:
  /// **'Add the first need'**
  String get addFirstNeed;

  /// No description provided for @newNeedTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s needed?'**
  String get newNeedTitle;

  /// No description provided for @needTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get needTitleLabel;

  /// No description provided for @needTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Milk'**
  String get needTitleHint;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Any detail — brand, size, where to buy'**
  String get noteHint;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @unitHint.
  ///
  /// In en, this message translates to:
  /// **'L, kg, box'**
  String get unitHint;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @assignToLabel.
  ///
  /// In en, this message translates to:
  /// **'Assign to'**
  String get assignToLabel;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get unassigned;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Needed'**
  String get statusOpen;

  /// No description provided for @statusClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get statusClaimed;

  /// No description provided for @statusPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get statusPurchased;

  /// No description provided for @statusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get statusArchived;

  /// No description provided for @markPurchased.
  ///
  /// In en, this message translates to:
  /// **'Mark purchased'**
  String get markPurchased;

  /// No description provided for @markOpen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get markOpen;

  /// No description provided for @claim.
  ///
  /// In en, this message translates to:
  /// **'I\'ll get it'**
  String get claim;

  /// No description provided for @unclaim.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get unclaim;

  /// No description provided for @claimedBy.
  ///
  /// In en, this message translates to:
  /// **'Claimed by {name}'**
  String claimedBy(String name);

  /// No description provided for @addedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by {name}'**
  String addedBy(String name);

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get priorityNormal;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @categoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryGroceries;

  /// No description provided for @categoryHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get categoryHousehold;

  /// No description provided for @categoryPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get categoryPharmacy;

  /// No description provided for @categoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get categoryPersonal;

  /// No description provided for @categoryKids.
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get categoryKids;

  /// No description provided for @categoryKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get categoryKitchen;

  /// No description provided for @categoryElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get categoryElectronics;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Items you purchase or archive will show up here.'**
  String get historyEmptyBody;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterStatus;

  /// No description provided for @filterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategory;

  /// No description provided for @filterPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get filterPriority;

  /// No description provided for @filterAssignee.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get filterAssignee;

  /// No description provided for @filterDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get filterDateRange;

  /// No description provided for @filterSearch.
  ///
  /// In en, this message translates to:
  /// **'Search items'**
  String get filterSearch;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearFilters;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get applyFilters;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String resultsCount(int count);

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No items match'**
  String get noResultsTitle;

  /// No description provided for @noResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try loosening the filters.'**
  String get noResultsBody;

  /// No description provided for @itemDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemDetailTitle;

  /// No description provided for @attachmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachmentsTitle;

  /// No description provided for @addLink.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get addLink;

  /// No description provided for @addFile.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get addFile;

  /// No description provided for @linkUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Link URL'**
  String get linkUrlLabel;

  /// No description provided for @linkNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get linkNameLabel;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @noAttachments.
  ///
  /// In en, this message translates to:
  /// **'No attachments yet'**
  String get noAttachments;

  /// No description provided for @openAttachment.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openAttachment;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAttachment;

  /// No description provided for @attachmentAdded.
  ///
  /// In en, this message translates to:
  /// **'Attached {name}'**
  String attachmentAdded(String name);

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploading;

  /// No description provided for @activityCreated.
  ///
  /// In en, this message translates to:
  /// **'{name} added this'**
  String activityCreated(String name);

  /// No description provided for @activityStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'{name} changed status from {from} to {to}'**
  String activityStatusChanged(String name, String from, String to);

  /// No description provided for @activityEdited.
  ///
  /// In en, this message translates to:
  /// **'{name} edited the item'**
  String activityEdited(String name);

  /// No description provided for @activityAssigned.
  ///
  /// In en, this message translates to:
  /// **'{name} assigned it to {to}'**
  String activityAssigned(String name, String to);

  /// No description provided for @activityAttachment.
  ///
  /// In en, this message translates to:
  /// **'{name} attached {to}'**
  String activityAttachment(String name, String to);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @familySection.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familySection;

  /// No description provided for @membersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTitle;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite someone'**
  String get inviteTitle;

  /// No description provided for @inviteBody.
  ///
  /// In en, this message translates to:
  /// **'Share this code. Anyone with it can join your family.'**
  String get inviteBody;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get linkCopied;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLink;

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String memberCount(int count);

  /// No description provided for @ownerBadge.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerBadge;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeMember;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this family?'**
  String removeMemberConfirm(String name);

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Push notifications on'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Push notifications off'**
  String get notificationsDisabled;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get enableNotifications;

  /// No description provided for @updatesSection.
  ///
  /// In en, this message translates to:
  /// **'App updates'**
  String get updatesSection;

  /// No description provided for @updateCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Installed version'**
  String get updateCurrentVersion;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checkingForUpdates;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version'**
  String get upToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updateAvailable(String version);

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download and install'**
  String get updateDownload;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String updateDownloading(int percent);

  /// No description provided for @updateInstall.
  ///
  /// In en, this message translates to:
  /// **'Install now'**
  String get updateInstall;

  /// No description provided for @updateInstalling.
  ///
  /// In en, this message translates to:
  /// **'Opening installer…'**
  String get updateInstalling;

  /// No description provided for @updatePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow installs'**
  String get updatePermissionTitle;

  /// No description provided for @updatePermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Android needs your permission before it can install the update. Turn on \"Allow from this source\" for Lazim, then come back.'**
  String get updatePermissionBody;

  /// No description provided for @updatePermissionAction.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get updatePermissionAction;

  /// No description provided for @updateInstallerOpened.
  ///
  /// In en, this message translates to:
  /// **'Follow the Android prompt to finish installing.'**
  String get updateInstallerOpened;

  /// No description provided for @updateErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the update server. Check your connection.'**
  String get updateErrorNetwork;

  /// No description provided for @updateErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'The update couldn\'t be completed. Try again.'**
  String get updateErrorGeneric;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateMandatoryNote.
  ///
  /// In en, this message translates to:
  /// **'This update is required to keep using the app.'**
  String get updateMandatoryNote;

  /// No description provided for @updatesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Update checks aren\'t configured in this build.'**
  String get updatesDisabled;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @notifNewItemTitle.
  ///
  /// In en, this message translates to:
  /// **'New item added'**
  String get notifNewItemTitle;

  /// No description provided for @notifNewItemBody.
  ///
  /// In en, this message translates to:
  /// **'{name} added \"{item}\"'**
  String notifNewItemBody(String name, String item);

  /// No description provided for @notifStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Item updated'**
  String get notifStatusTitle;

  /// No description provided for @notifStatusBody.
  ///
  /// In en, this message translates to:
  /// **'{name} marked \"{item}\" as {status}'**
  String notifStatusBody(String name, String item, String status);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network.'**
  String get errorNetwork;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This is required'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get weakPassword;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @quickAddHint.
  ///
  /// In en, this message translates to:
  /// **'Add an item…'**
  String get quickAddHint;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search items…'**
  String get searchHint;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No matching items'**
  String get noSearchResults;

  /// No description provided for @selectMode.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectMode;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelection;

  /// No description provided for @bulkMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get bulkMarkDone;

  /// No description provided for @bulkDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get bulkDelete;

  /// No description provided for @bulkCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bulkCancel;

  /// No description provided for @bulkDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} items?'**
  String bulkDeleteConfirm(int count);

  /// No description provided for @swipeShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get swipeShare;

  /// No description provided for @swipeDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get swipeDelete;

  /// No description provided for @itemShared.
  ///
  /// In en, this message translates to:
  /// **'Item shared'**
  String get itemShared;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editName;

  /// No description provided for @editNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get editNameTitle;

  /// No description provided for @editNameHint.
  ///
  /// In en, this message translates to:
  /// **'The name your family sees'**
  String get editNameHint;

  /// No description provided for @nameSaved.
  ///
  /// In en, this message translates to:
  /// **'Name saved'**
  String get nameSaved;

  /// No description provided for @attachmentUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload the file. Check that Firebase Storage is enabled.'**
  String get attachmentUploadFailed;

  /// No description provided for @attachmentOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file.'**
  String get attachmentOpenFailed;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppL10nAr();
    case 'en':
      return AppL10nEn();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
