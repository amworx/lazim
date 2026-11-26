// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Lazim';

  @override
  String get appTagline => 'Everything the home needs, in one place.';

  @override
  String get signInTitle => 'Welcome to Lazim';

  @override
  String get signInSubtitle =>
      'One shared list for everything your home needs. No more digging through chats.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithEmail => 'Continue with email';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get nameLabel => 'Your name';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Sign out of Lazim?';

  @override
  String get demoModeBanner => 'Demo mode — data stays on this device';

  @override
  String get orDivider => 'or';

  @override
  String get familySetupTitle => 'Set up your home';

  @override
  String get familySetupSubtitle =>
      'Create a family group, or join one with an invite code.';

  @override
  String get createFamily => 'Create a family';

  @override
  String get joinFamily => 'Join a family';

  @override
  String get familyNameLabel => 'Family name';

  @override
  String get familyNameHint => 'e.g. Home, Al-Sayed family';

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get inviteCodeHint => 'LAZIM-XXXXXX';

  @override
  String get create => 'Create';

  @override
  String get join => 'Join';

  @override
  String get joining => 'Joining…';

  @override
  String get creating => 'Creating…';

  @override
  String get inviteNotFound =>
      'That invite code doesn\'t exist. Check it and try again.';

  @override
  String get needsTitle => 'Needs';

  @override
  String get needsEmptyTitle => 'Nothing needed right now';

  @override
  String get needsEmptyBody =>
      'Add the first thing your home needs. Groceries, medicine, a light bulb — anything.';

  @override
  String get addNeed => 'Add a need';

  @override
  String get addFirstNeed => 'Add the first need';

  @override
  String get newNeedTitle => 'What\'s needed?';

  @override
  String get needTitleLabel => 'Item';

  @override
  String get needTitleHint => 'e.g. Milk';

  @override
  String get noteLabel => 'Note';

  @override
  String get noteHint => 'Any detail — brand, size, where to buy';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get unitLabel => 'Unit';

  @override
  String get unitHint => 'L, kg, box';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get categoryLabel => 'Category';

  @override
  String get assignToLabel => 'Assign to';

  @override
  String get unassigned => 'Anyone';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Try again';

  @override
  String get statusOpen => 'Needed';

  @override
  String get statusClaimed => 'Claimed';

  @override
  String get statusPurchased => 'Purchased';

  @override
  String get statusArchived => 'Archived';

  @override
  String get markPurchased => 'Mark purchased';

  @override
  String get markOpen => 'Reopen';

  @override
  String get claim => 'I\'ll get it';

  @override
  String get unclaim => 'Release';

  @override
  String claimedBy(String name) {
    return 'Claimed by $name';
  }

  @override
  String addedBy(String name) {
    return 'Added by $name';
  }

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get categoryGroceries => 'Groceries';

  @override
  String get categoryHousehold => 'Household';

  @override
  String get categoryPharmacy => 'Pharmacy';

  @override
  String get categoryPersonal => 'Personal';

  @override
  String get categoryKids => 'Kids';

  @override
  String get categoryKitchen => 'Kitchen';

  @override
  String get categoryElectronics => 'Electronics';

  @override
  String get categoryOther => 'Other';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmptyTitle => 'No history yet';

  @override
  String get historyEmptyBody =>
      'Items you purchase or archive will show up here.';

  @override
  String get filters => 'Filters';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterPriority => 'Priority';

  @override
  String get filterAssignee => 'Assigned to';

  @override
  String get filterDateRange => 'Date range';

  @override
  String get filterSearch => 'Search items';

  @override
  String get clearFilters => 'Clear all';

  @override
  String get applyFilters => 'Show results';

  @override
  String resultsCount(int count) {
    return '$count items';
  }

  @override
  String get noResultsTitle => 'No items match';

  @override
  String get noResultsBody => 'Try loosening the filters.';

  @override
  String get itemDetailTitle => 'Item';

  @override
  String get attachmentsTitle => 'Attachments';

  @override
  String get addLink => 'Add link';

  @override
  String get addFile => 'Attach file';

  @override
  String get linkUrlLabel => 'Link URL';

  @override
  String get linkNameLabel => 'Label';

  @override
  String get activityTitle => 'Activity';

  @override
  String get noAttachments => 'No attachments yet';

  @override
  String get openAttachment => 'Open';

  @override
  String get removeAttachment => 'Remove';

  @override
  String attachmentAdded(String name) {
    return 'Attachment added';
  }

  @override
  String get uploading => 'Uploading…';

  @override
  String activityCreated(String name) {
    return '$name added this';
  }

  @override
  String activityStatusChanged(String name, String from, String to) {
    return '$name changed status from $from to $to';
  }

  @override
  String activityEdited(String name) {
    return '$name edited the item';
  }

  @override
  String activityAssigned(String name, String to) {
    return '$name assigned it to $to';
  }

  @override
  String activityAttachment(String name, String to) {
    return '$name attached $to';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get familySection => 'Family';

  @override
  String get membersTitle => 'Members';

  @override
  String get inviteTitle => 'Invite someone';

  @override
  String get inviteBody =>
      'Share this code. Anyone with it can join your family.';

  @override
  String get copyLink => 'Copy code';

  @override
  String get linkCopied => 'Code copied';

  @override
  String get shareLink => 'Share';

  @override
  String memberCount(int count) {
    return '$count members';
  }

  @override
  String get ownerBadge => 'Owner';

  @override
  String get removeMember => 'Remove';

  @override
  String removeMemberConfirm(String name) {
    return 'Remove $name from this family?';
  }

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get notificationsEnabled => 'Push notifications on';

  @override
  String get notificationsDisabled => 'Push notifications off';

  @override
  String get enableNotifications => 'Turn on notifications';

  @override
  String get updatesSection => 'App updates';

  @override
  String get updateCurrentVersion => 'Installed version';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkingForUpdates => 'Checking…';

  @override
  String get upToDate => 'You\'re on the latest version';

  @override
  String updateAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String get updateDownload => 'Download and install';

  @override
  String updateDownloading(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get updateInstall => 'Install now';

  @override
  String get updateInstalling => 'Opening installer…';

  @override
  String get updatePermissionTitle => 'Allow installs';

  @override
  String get updatePermissionBody =>
      'Android needs your permission before it can install the update. Turn on \"Allow from this source\" for Lazim, then come back.';

  @override
  String get updatePermissionAction => 'Open settings';

  @override
  String get updateInstallerOpened =>
      'Follow the Android prompt to finish installing.';

  @override
  String get updateErrorNetwork =>
      'Couldn\'t reach the update server. Check your connection.';

  @override
  String get updateErrorGeneric =>
      'The update couldn\'t be completed. Try again.';

  @override
  String get updateLater => 'Later';

  @override
  String get updateMandatoryNote =>
      'This update is required to keep using the app.';

  @override
  String get updatesDisabled =>
      'Update checks aren\'t configured in this build.';

  @override
  String get aboutSection => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get notifNewItemTitle => 'New item added';

  @override
  String notifNewItemBody(String name, String item) {
    return '$name added \"$item\"';
  }

  @override
  String get notifStatusTitle => 'Item updated';

  @override
  String notifStatusBody(String name, String item, String status) {
    return '$name marked \"$item\" as $status';
  }

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get errorNetwork => 'No connection. Check your network.';

  @override
  String get requiredField => 'This is required';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get weakPassword => 'Use at least 6 characters';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get quickAddHint => 'Add an item…';

  @override
  String get searchHint => 'Search items…';

  @override
  String get searchClear => 'Clear search';

  @override
  String get noSearchResults => 'No matching items';

  @override
  String get selectMode => 'Select';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get bulkMarkDone => 'Mark done';

  @override
  String get bulkDelete => 'Delete';

  @override
  String get bulkCancel => 'Cancel';

  @override
  String bulkDeleteConfirm(int count) {
    return 'Delete $count items?';
  }

  @override
  String get swipeShare => 'Share';

  @override
  String get swipeDelete => 'Delete';

  @override
  String get itemShared => 'Item shared';

  @override
  String get editName => 'Edit name';

  @override
  String get editNameTitle => 'Display name';

  @override
  String get editNameHint => 'The name your family sees';

  @override
  String get nameSaved => 'Name saved';

  @override
  String get attachmentUploadFailed =>
      'Could not upload the file. Check your connection and try again.';

  @override
  String get attachmentOpenFailed => 'Could not open the file.';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesSubtitle =>
      'Organise the home\'s needs with your own categories';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get addCategory => 'New category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categoryNameLabel => 'Category name';

  @override
  String get categoryNameHint => 'e.g. Garden supplies';

  @override
  String get categoryIconLabel => 'Icon';

  @override
  String get categoryAdded => 'Category added';

  @override
  String get categoryRenamed => 'Category updated';

  @override
  String get categoryDeleted => 'Category deleted';

  @override
  String categoryDeleteConfirm(String name) {
    return 'Delete \"$name\"? Items keep their other categories.';
  }

  @override
  String get categoriesEmpty => 'No custom categories yet';

  @override
  String get categoriesEmptyBody =>
      'The default categories are ready to use. Add one of your own.';

  @override
  String get builtInCategories => 'Default categories';

  @override
  String get customCategories => 'Your categories';

  @override
  String get selectCategories => 'Categories';

  @override
  String get categoriesHint => 'You can pick more than one';

  @override
  String get addAttachment => 'Add attachment';

  @override
  String get attachmentsHint => 'Add photos, files or links';

  @override
  String get attachmentPreview => 'Preview';

  @override
  String get imagePreviewTitle => 'Image preview';

  @override
  String get attachmentTooLarge => 'Files must be under 5 MB.';

  @override
  String get attachmentEmpty => 'This file is empty.';

  @override
  String get notificationsCleared => 'Notifications cleared';

  @override
  String get noCategoriesSelected => 'No category';
}
