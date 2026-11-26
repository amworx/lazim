// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppL10nAr extends AppL10n {
  AppL10nAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'لازم';

  @override
  String get appTagline => 'كل احتياجات البيت في مكان واحد.';

  @override
  String get signInTitle => 'أهلاً بك في لازم';

  @override
  String get signInSubtitle =>
      'قائمة واحدة مشتركة لكل ما يحتاجه بيتك. لا مزيد من البحث بين المحادثات.';

  @override
  String get continueWithGoogle => 'المتابعة بحساب Google';

  @override
  String get continueWithEmail => 'المتابعة بالبريد الإلكتروني';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get nameLabel => 'اسمك';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirm => 'تسجيل الخروج من لازم؟';

  @override
  String get demoModeBanner =>
      'الوضع التجريبي — البيانات محفوظة على هذا الجهاز';

  @override
  String get orDivider => 'أو';

  @override
  String get familySetupTitle => 'جهّز بيتك';

  @override
  String get familySetupSubtitle =>
      'أنشئ مجموعة عائلية، أو انضم لواحدة بكود الدعوة.';

  @override
  String get createFamily => 'إنشاء مجموعة عائلية';

  @override
  String get joinFamily => 'الانضمام لمجموعة';

  @override
  String get familyNameLabel => 'اسم المجموعة';

  @override
  String get familyNameHint => 'مثال: البيت، عائلة السيد';

  @override
  String get inviteCodeLabel => 'كود الدعوة';

  @override
  String get inviteCodeHint => 'LAZIM-XXXXXX';

  @override
  String get create => 'إنشاء';

  @override
  String get join => 'انضمام';

  @override
  String get joining => 'جارٍ الانضمام…';

  @override
  String get creating => 'جارٍ الإنشاء…';

  @override
  String get inviteNotFound => 'كود الدعوة غير موجود. تأكد منه وحاول مرة أخرى.';

  @override
  String get needsTitle => 'الاحتياجات';

  @override
  String get needsEmptyTitle => 'لا يوجد شيء مطلوب حالياً';

  @override
  String get needsEmptyBody =>
      'أضف أول شيء يحتاجه بيتك. بقالة، دواء، لمبة — أي شيء.';

  @override
  String get addNeed => 'إضافة احتياج';

  @override
  String get addFirstNeed => 'أضف أول احتياج';

  @override
  String get newNeedTitle => 'ما المطلوب؟';

  @override
  String get needTitleLabel => 'الصنف';

  @override
  String get needTitleHint => 'مثال: حليب';

  @override
  String get noteLabel => 'ملاحظة';

  @override
  String get noteHint => 'أي تفصيل — الماركة، الحجم، من أين تشتريه';

  @override
  String get quantityLabel => 'الكمية';

  @override
  String get unitLabel => 'الوحدة';

  @override
  String get unitHint => 'لتر، كجم، علبة';

  @override
  String get priorityLabel => 'الأولوية';

  @override
  String get categoryLabel => 'الفئة';

  @override
  String get assignToLabel => 'مسؤول عن الشراء';

  @override
  String get unassigned => 'أي شخص';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get done => 'تم';

  @override
  String get retry => 'حاول مرة أخرى';

  @override
  String get statusOpen => 'مطلوب';

  @override
  String get statusClaimed => 'محجوز';

  @override
  String get statusPurchased => 'تم الشراء';

  @override
  String get statusArchived => 'مؤرشف';

  @override
  String get markPurchased => 'تم الشراء';

  @override
  String get markOpen => 'إعادة فتح';

  @override
  String get claim => 'أنا سأحضره';

  @override
  String get unclaim => 'إلغاء الحجز';

  @override
  String claimedBy(String name) {
    return 'محجوز بواسطة $name';
  }

  @override
  String addedBy(String name) {
    return 'أضافه $name';
  }

  @override
  String get priorityLow => 'منخفضة';

  @override
  String get priorityNormal => 'عادية';

  @override
  String get priorityUrgent => 'عاجلة';

  @override
  String get categoryGroceries => 'بقالة';

  @override
  String get categoryHousehold => 'مستلزمات المنزل';

  @override
  String get categoryPharmacy => 'صيدلية';

  @override
  String get categoryPersonal => 'عناية شخصية';

  @override
  String get categoryKids => 'الأطفال';

  @override
  String get categoryKitchen => 'المطبخ';

  @override
  String get categoryElectronics => 'إلكترونيات';

  @override
  String get categoryOther => 'أخرى';

  @override
  String get historyTitle => 'السجل';

  @override
  String get historyEmptyTitle => 'لا يوجد سجل بعد';

  @override
  String get historyEmptyBody => 'الأصناف التي تشتريها أو تؤرشفها ستظهر هنا.';

  @override
  String get filters => 'الفلاتر';

  @override
  String get filterStatus => 'الحالة';

  @override
  String get filterCategory => 'الفئة';

  @override
  String get filterPriority => 'الأولوية';

  @override
  String get filterAssignee => 'المسؤول';

  @override
  String get filterDateRange => 'الفترة الزمنية';

  @override
  String get filterSearch => 'ابحث في الأصناف';

  @override
  String get clearFilters => 'مسح الكل';

  @override
  String get applyFilters => 'عرض النتائج';

  @override
  String resultsCount(int count) {
    return '$count صنف';
  }

  @override
  String get noResultsTitle => 'لا توجد نتائج مطابقة';

  @override
  String get noResultsBody => 'جرّب توسيع الفلاتر.';

  @override
  String get itemDetailTitle => 'الصنف';

  @override
  String get attachmentsTitle => 'المرفقات';

  @override
  String get addLink => 'إضافة رابط';

  @override
  String get addFile => 'إرفاق ملف';

  @override
  String get linkUrlLabel => 'رابط';

  @override
  String get linkNameLabel => 'الاسم';

  @override
  String get activityTitle => 'النشاط';

  @override
  String get noAttachments => 'لا توجد مرفقات بعد';

  @override
  String get openAttachment => 'فتح';

  @override
  String get removeAttachment => 'إزالة';

  @override
  String attachmentAdded(String name) {
    return 'أرفق $name';
  }

  @override
  String get uploading => 'جارٍ الرفع…';

  @override
  String activityCreated(String name) {
    return '$name أضاف هذا';
  }

  @override
  String activityStatusChanged(String name, String from, String to) {
    return '$name غيّر الحالة من $from إلى $to';
  }

  @override
  String activityEdited(String name) {
    return '$name عدّل الصنف';
  }

  @override
  String activityAssigned(String name, String to) {
    return '$name أسنده إلى $to';
  }

  @override
  String activityAttachment(String name, String to) {
    return '$name أرفق $to';
  }

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get familySection => 'المجموعة العائلية';

  @override
  String get membersTitle => 'الأعضاء';

  @override
  String get inviteTitle => 'دعوة شخص';

  @override
  String get inviteBody => 'شارك هذا الكود. من يملكه يمكنه الانضمام لمجموعتك.';

  @override
  String get copyLink => 'نسخ الكود';

  @override
  String get linkCopied => 'تم نسخ الكود';

  @override
  String get shareLink => 'مشاركة';

  @override
  String memberCount(int count) {
    return '$count أعضاء';
  }

  @override
  String get ownerBadge => 'المالك';

  @override
  String get removeMember => 'إزالة';

  @override
  String removeMemberConfirm(String name) {
    return 'إزالة $name من هذه المجموعة؟';
  }

  @override
  String get notificationsSection => 'الإشعارات';

  @override
  String get notificationsEnabled => 'الإشعارات مفعّلة';

  @override
  String get notificationsDisabled => 'الإشعارات متوقفة';

  @override
  String get enableNotifications => 'تفعيل الإشعارات';

  @override
  String get updatesSection => 'تحديثات التطبيق';

  @override
  String get updateCurrentVersion => 'الإصدار المثبّت';

  @override
  String get checkForUpdates => 'البحث عن تحديثات';

  @override
  String get checkingForUpdates => 'جارٍ البحث…';

  @override
  String get upToDate => 'أنت على أحدث إصدار';

  @override
  String updateAvailable(String version) {
    return 'الإصدار $version متاح';
  }

  @override
  String get updateDownload => 'تنزيل وتثبيت';

  @override
  String updateDownloading(int percent) {
    return 'جارٍ التنزيل… $percent%';
  }

  @override
  String get updateInstall => 'تثبيت الآن';

  @override
  String get updateInstalling => 'جارٍ فتح المثبّت…';

  @override
  String get updatePermissionTitle => 'السماح بالتثبيت';

  @override
  String get updatePermissionBody =>
      'يحتاج أندرويد إلى إذنك قبل تثبيت التحديث. فعّل «السماح من هذا المصدر» لتطبيق لازم ثم ارجع.';

  @override
  String get updatePermissionAction => 'فتح الإعدادات';

  @override
  String get updateInstallerOpened => 'أكمل التثبيت من نافذة أندرويد.';

  @override
  String get updateErrorNetwork =>
      'تعذّر الوصول إلى خادم التحديثات. تحقّق من اتصالك.';

  @override
  String get updateErrorGeneric => 'لم يكتمل التحديث. حاول مرة أخرى.';

  @override
  String get updateLater => 'لاحقًا';

  @override
  String get updateMandatoryNote =>
      'هذا التحديث مطلوب لمواصلة استخدام التطبيق.';

  @override
  String get updatesDisabled => 'البحث عن التحديثات غير مُهيّأ في هذا الإصدار.';

  @override
  String get aboutSection => 'حول التطبيق';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String get notifNewItemTitle => 'صنف جديد';

  @override
  String notifNewItemBody(String name, String item) {
    return '$name أضاف \"$item\"';
  }

  @override
  String get notifStatusTitle => 'تحديث على صنف';

  @override
  String notifStatusBody(String name, String item, String status) {
    return '$name غيّر حالة \"$item\" إلى $status';
  }

  @override
  String get errorGeneric => 'حدث خطأ. حاول مرة أخرى.';

  @override
  String get errorNetwork => 'لا يوجد اتصال. تحقق من الشبكة.';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get invalidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get weakPassword => 'استخدم 6 أحرف على الأقل';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String daysAgo(int count) {
    return 'قبل $count يوم';
  }

  @override
  String get quickAddHint => 'أضف صنفاً…';
}
