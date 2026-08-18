import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('mr')];
  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings(Locale('en'));

  String text(String key, {Map<String, Object> params = const {}}) {
    final language = _translations.containsKey(locale.languageCode)
        ? locale.languageCode
        : 'en';
    var value =
        _translations[language]?[key] ?? _translations['en']?[key] ?? key;
    for (final entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return value;
  }

  String get appName => text('appName');
  String get appTagline => text('appTagline');
  String get demoMode => text('demoMode');
  String get home => text('home');
  String get services => text('services');
  String get myRequests => text('myRequests');
  String get notifications => text('notifications');
  String get profile => text('profile');
  String get next => text('next');
  String get skip => text('skip');
  String get getStarted => text('getStarted');
  String get continueLabel => text('continue');
  String get back => text('back');
  String get cancel => text('cancel');
  String get save => text('save');
  String get submit => text('submit');
  String get edit => text('edit');
  String get retry => text('retry');
  String get done => text('done');
  String get login => text('login');
  String get register => text('register');
  String get logout => text('logout');
  String get phone => text('phone');
  String get email => text('email');
  String get password => text('password');
  String get fullName => text('fullName');
  String get search => text('search');
  String get loading => text('loading');
  String get somethingWentWrong => text('somethingWentWrong');
  String get noResults => text('noResults');
  String get all => text('all');
  String get active => text('active');
  String get resolved => text('resolved');
  String get important => text('important');
  String get requests => text('requests');
  String get cityUpdates => text('cityUpdates');
  String get chooseCivicService => text('chooseCivicService');
  String get howCanWeHelp => text('howCanWeHelp');
  String get reportSubmitted => text('reportSubmitted');
  String get trackRequest => text('trackRequest');
  String get currentLocation => text('currentLocation');
  String get confirmLocation => text('confirmLocation');
  String get adjustPin => text('adjustPin');
  String get lowLocationAccuracy => text('lowLocationAccuracy');
  String get takePhoto => text('takePhoto');
  String get chooseFromGallery => text('chooseFromGallery');
  String get removePhoto => text('removePhoto');
  String get english => text('english');
  String get marathi => text('marathi');

  static const _translations = <String, Map<String, String>>{
    'en': {
      'appName': 'NGP Seva',
      'appTagline': 'Your city. One simple place.',
      'demoMode': 'Demo mode',
      'home': 'Home',
      'services': 'Services',
      'myRequests': 'My Requests',
      'notifications': 'Notifications',
      'profile': 'Profile',
      'next': 'Next',
      'skip': 'Skip',
      'getStarted': 'Get Started',
      'continue': 'Continue',
      'back': 'Back',
      'cancel': 'Cancel',
      'save': 'Save',
      'submit': 'Submit',
      'edit': 'Edit',
      'retry': 'Retry',
      'done': 'Done',
      'login': 'Log in',
      'register': 'Register',
      'logout': 'Log out',
      'phone': 'Mobile number',
      'email': 'Email',
      'password': 'Password',
      'fullName': 'Full name',
      'search': 'Search',
      'loading': 'Loading…',
      'somethingWentWrong': 'Something went wrong',
      'noResults': 'No results found',
      'all': 'All',
      'active': 'Active',
      'resolved': 'Resolved',
      'important': 'Important',
      'requests': 'Requests',
      'cityUpdates': 'City Updates',
      'chooseCivicService': 'Choose a civic service',
      'howCanWeHelp': 'How can we help you?',
      'reportSubmitted': 'Report Submitted',
      'trackRequest': 'Track Request',
      'currentLocation': 'Use Current Location',
      'confirmLocation': 'Confirm Location',
      'adjustPin': 'Adjust Pin',
      'lowLocationAccuracy':
          'Your location accuracy is low. Try again or adjust the pin.',
      'takePhoto': 'Take Photo',
      'chooseFromGallery': 'Choose from Gallery',
      'removePhoto': 'Remove Photo',
      'english': 'English',
      'marathi': 'Marathi',
    },
    'mr': {
      'appName': 'एनजीपी सेवा',
      'appTagline': 'आपले शहर. एक सोपे ठिकाण.',
      'demoMode': 'डेमो मोड',
      'home': 'मुख्यपृष्ठ',
      'services': 'सेवा',
      'myRequests': 'माझ्या विनंत्या',
      'notifications': 'सूचना',
      'profile': 'प्रोफाइल',
      'next': 'पुढे',
      'skip': 'वगळा',
      'getStarted': 'सुरू करा',
      'continue': 'पुढे चला',
      'back': 'मागे',
      'cancel': 'रद्द करा',
      'save': 'जतन करा',
      'submit': 'सादर करा',
      'edit': 'बदला',
      'retry': 'पुन्हा प्रयत्न करा',
      'done': 'पूर्ण',
      'login': 'लॉग इन',
      'register': 'नोंदणी',
      'logout': 'लॉग आउट',
      'phone': 'मोबाइल क्रमांक',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'fullName': 'पूर्ण नाव',
      'search': 'शोधा',
      'loading': 'लोड होत आहे…',
      'somethingWentWrong': 'काहीतरी चूक झाली',
      'noResults': 'कोणतेही निकाल सापडले नाहीत',
      'all': 'सर्व',
      'active': 'सक्रिय',
      'resolved': 'निराकरण झाले',
      'important': 'महत्त्वाचे',
      'requests': 'विनंत्या',
      'cityUpdates': 'शहर बातम्या',
      'chooseCivicService': 'नागरी सेवा निवडा',
      'howCanWeHelp': 'आम्ही आपली कशी मदत करू शकतो?',
      'reportSubmitted': 'अहवाल सादर झाला',
      'trackRequest': 'विनंतीचा मागोवा',
      'currentLocation': 'सध्याचे स्थान वापरा',
      'confirmLocation': 'स्थान निश्चित करा',
      'adjustPin': 'पिन बदला',
      'lowLocationAccuracy':
          'आपल्या स्थानाची अचूकता कमी आहे. पुन्हा प्रयत्न करा किंवा पिन बदला.',
      'takePhoto': 'फोटो काढा',
      'chooseFromGallery': 'गॅलरीमधून निवडा',
      'removePhoto': 'फोटो काढून टाका',
      'english': 'इंग्रजी',
      'marathi': 'मराठी',
    },
  };
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => AppStrings.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale));

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
