import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmTitle;

  /// No description provided for @confirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to proceed?'**
  String get confirmContent;

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get confirmCancel;

  /// No description provided for @confirmOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirmOk;

  /// Notification message when an item is added to the playback queue.
  ///
  /// In en, this message translates to:
  /// **'Appended to queue: {title}'**
  String appendedToQueue(String title);

  /// No description provided for @appendMediaToQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Append to Queue'**
  String get appendMediaToQueueTitle;

  /// Description for appending media to the playback queue.
  ///
  /// In en, this message translates to:
  /// **'Append the media to the end of the playback queue: {title}'**
  String appendMediaToQueueDescription(String title);

  /// No description provided for @loadingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Loading, please wait...'**
  String get loadingPleaseWait;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlaying;

  /// No description provided for @mediaPlayer.
  ///
  /// In en, this message translates to:
  /// **'Media Player'**
  String get mediaPlayer;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @seekForward.
  ///
  /// In en, this message translates to:
  /// **'Seek Forward'**
  String get seekForward;

  /// No description provided for @seekBackward.
  ///
  /// In en, this message translates to:
  /// **'Seek Backward'**
  String get seekBackward;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @arts.
  ///
  /// In en, this message translates to:
  /// **'Arts'**
  String get arts;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @comedy.
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get comedy;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @fiction.
  ///
  /// In en, this message translates to:
  /// **'Fiction'**
  String get fiction;

  /// No description provided for @government.
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get government;

  /// No description provided for @healthAndFitness.
  ///
  /// In en, this message translates to:
  /// **'Health & Fitness'**
  String get healthAndFitness;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @kidsAndFamily.
  ///
  /// In en, this message translates to:
  /// **'Kids & Family'**
  String get kidsAndFamily;

  /// No description provided for @leisure.
  ///
  /// In en, this message translates to:
  /// **'Leisure'**
  String get leisure;

  /// No description provided for @news.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get news;

  /// No description provided for @religionAndSpirituality.
  ///
  /// In en, this message translates to:
  /// **'Religion & Spirituality'**
  String get religionAndSpirituality;

  /// No description provided for @science.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get science;

  /// No description provided for @societyAndCulture.
  ///
  /// In en, this message translates to:
  /// **'Society & Culture'**
  String get societyAndCulture;

  /// No description provided for @sports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get sports;

  /// No description provided for @tvAndFilm.
  ///
  /// In en, this message translates to:
  /// **'TV & Film'**
  String get tvAndFilm;

  /// No description provided for @technology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get technology;

  /// No description provided for @trueCrime.
  ///
  /// In en, this message translates to:
  /// **'True Crime'**
  String get trueCrime;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @astronomyXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Astronomy'**
  String get astronomyXXXPodcastIndexOnly;

  /// No description provided for @automotiveXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Automotive'**
  String get automotiveXXXPodcastIndexOnly;

  /// No description provided for @aviationXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Aviation'**
  String get aviationXXXPodcastIndexOnly;

  /// No description provided for @baseballXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Baseball'**
  String get baseballXXXPodcastIndexOnly;

  /// No description provided for @basketballXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Basketball'**
  String get basketballXXXPodcastIndexOnly;

  /// No description provided for @beautyXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get beautyXXXPodcastIndexOnly;

  /// No description provided for @booksXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get booksXXXPodcastIndexOnly;

  /// No description provided for @buddhismXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Buddhism'**
  String get buddhismXXXPodcastIndexOnly;

  /// No description provided for @careersXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Careers'**
  String get careersXXXPodcastIndexOnly;

  /// No description provided for @chemistryXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get chemistryXXXPodcastIndexOnly;

  /// No description provided for @christianityXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Christianity'**
  String get christianityXXXPodcastIndexOnly;

  /// No description provided for @climateXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Climate'**
  String get climateXXXPodcastIndexOnly;

  /// No description provided for @commentaryXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Commentary'**
  String get commentaryXXXPodcastIndexOnly;

  /// No description provided for @coursesXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get coursesXXXPodcastIndexOnly;

  /// No description provided for @craftsXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Crafts'**
  String get craftsXXXPodcastIndexOnly;

  /// No description provided for @cricketXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Cricket'**
  String get cricketXXXPodcastIndexOnly;

  /// No description provided for @cryptocurrencyXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Cryptocurrency'**
  String get cryptocurrencyXXXPodcastIndexOnly;

  /// No description provided for @cultureXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get cultureXXXPodcastIndexOnly;

  /// No description provided for @dailyXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyXXXPodcastIndexOnly;

  /// No description provided for @designXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get designXXXPodcastIndexOnly;

  /// No description provided for @documentaryXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Documentary'**
  String get documentaryXXXPodcastIndexOnly;

  /// No description provided for @dramaXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Drama'**
  String get dramaXXXPodcastIndexOnly;

  /// No description provided for @earthXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Earth'**
  String get earthXXXPodcastIndexOnly;

  /// No description provided for @entertainmentXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainmentXXXPodcastIndexOnly;

  /// No description provided for @entrepreneurshipXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Entrepreneurship'**
  String get entrepreneurshipXXXPodcastIndexOnly;

  /// No description provided for @familyXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familyXXXPodcastIndexOnly;

  /// No description provided for @fantasyXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Fantasy'**
  String get fantasyXXXPodcastIndexOnly;

  /// No description provided for @fashionXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Fashion'**
  String get fashionXXXPodcastIndexOnly;

  /// No description provided for @filmXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get filmXXXPodcastIndexOnly;

  /// No description provided for @fitnessXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get fitnessXXXPodcastIndexOnly;

  /// No description provided for @foodXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get foodXXXPodcastIndexOnly;

  /// No description provided for @footballXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Football'**
  String get footballXXXPodcastIndexOnly;

  /// No description provided for @gamesXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get gamesXXXPodcastIndexOnly;

  /// No description provided for @gardenXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get gardenXXXPodcastIndexOnly;

  /// No description provided for @golfXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Golf'**
  String get golfXXXPodcastIndexOnly;

  /// No description provided for @healthXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get healthXXXPodcastIndexOnly;

  /// No description provided for @hinduismXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Hinduism'**
  String get hinduismXXXPodcastIndexOnly;

  /// No description provided for @hobbiesXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Hobbies'**
  String get hobbiesXXXPodcastIndexOnly;

  /// No description provided for @hockeyXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Hockey'**
  String get hockeyXXXPodcastIndexOnly;

  /// No description provided for @homeXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeXXXPodcastIndexOnly;

  /// No description provided for @howToXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'How To'**
  String get howToXXXPodcastIndexOnly;

  /// No description provided for @improvXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Improv'**
  String get improvXXXPodcastIndexOnly;

  /// No description provided for @interviewsXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Interviews'**
  String get interviewsXXXPodcastIndexOnly;

  /// No description provided for @investingXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Investing'**
  String get investingXXXPodcastIndexOnly;

  /// No description provided for @islamXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Islam'**
  String get islamXXXPodcastIndexOnly;

  /// No description provided for @journalsXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Journals'**
  String get journalsXXXPodcastIndexOnly;

  /// No description provided for @judaismXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Judaism'**
  String get judaismXXXPodcastIndexOnly;

  /// No description provided for @kidsXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get kidsXXXPodcastIndexOnly;

  /// No description provided for @languageXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageXXXPodcastIndexOnly;

  /// No description provided for @learningXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learningXXXPodcastIndexOnly;

  /// No description provided for @lifeXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get lifeXXXPodcastIndexOnly;

  /// No description provided for @managementXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get managementXXXPodcastIndexOnly;

  /// No description provided for @mangaXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Manga'**
  String get mangaXXXPodcastIndexOnly;

  /// No description provided for @marketingXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get marketingXXXPodcastIndexOnly;

  /// No description provided for @mathematicsXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Mathematics'**
  String get mathematicsXXXPodcastIndexOnly;

  /// No description provided for @medicineXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medicineXXXPodcastIndexOnly;

  /// No description provided for @mentalXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Mental'**
  String get mentalXXXPodcastIndexOnly;

  /// No description provided for @naturalXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Natural'**
  String get naturalXXXPodcastIndexOnly;

  /// No description provided for @natureXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get natureXXXPodcastIndexOnly;

  /// No description provided for @nonProfitXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Non Profit'**
  String get nonProfitXXXPodcastIndexOnly;

  /// No description provided for @nutritionXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutritionXXXPodcastIndexOnly;

  /// No description provided for @parentingXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Parenting'**
  String get parentingXXXPodcastIndexOnly;

  /// No description provided for @performingXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Performing'**
  String get performingXXXPodcastIndexOnly;

  /// No description provided for @personalXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personalXXXPodcastIndexOnly;

  /// No description provided for @petsXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get petsXXXPodcastIndexOnly;

  /// No description provided for @philosophyXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Philosophy'**
  String get philosophyXXXPodcastIndexOnly;

  /// No description provided for @physicsXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Physics'**
  String get physicsXXXPodcastIndexOnly;

  /// No description provided for @placesXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get placesXXXPodcastIndexOnly;

  /// No description provided for @politicsXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Politics'**
  String get politicsXXXPodcastIndexOnly;

  /// No description provided for @relationshipsXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Relationships'**
  String get relationshipsXXXPodcastIndexOnly;

  /// No description provided for @religionXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get religionXXXPodcastIndexOnly;

  /// No description provided for @reviewsXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsXXXPodcastIndexOnly;

  /// No description provided for @rolePlayingXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Role Playing'**
  String get rolePlayingXXXPodcastIndexOnly;

  /// No description provided for @rugbyXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Rugby'**
  String get rugbyXXXPodcastIndexOnly;

  /// No description provided for @runningXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get runningXXXPodcastIndexOnly;

  /// No description provided for @selfImprovementXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Self Improvement'**
  String get selfImprovementXXXPodcastIndexOnly;

  /// No description provided for @sexualityXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Sexuality'**
  String get sexualityXXXPodcastIndexOnly;

  /// No description provided for @soccerXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Soccer'**
  String get soccerXXXPodcastIndexOnly;

  /// No description provided for @socialXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get socialXXXPodcastIndexOnly;

  /// No description provided for @societyXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Society'**
  String get societyXXXPodcastIndexOnly;

  /// No description provided for @spiritualityXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Spirituality'**
  String get spiritualityXXXPodcastIndexOnly;

  /// No description provided for @standUpXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'StandUp'**
  String get standUpXXXPodcastIndexOnly;

  /// No description provided for @storiesXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get storiesXXXPodcastIndexOnly;

  /// No description provided for @swimmingXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get swimmingXXXPodcastIndexOnly;

  /// No description provided for @tVXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'TV'**
  String get tVXXXPodcastIndexOnly;

  /// No description provided for @tabletopXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Tabletop'**
  String get tabletopXXXPodcastIndexOnly;

  /// No description provided for @tennisXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get tennisXXXPodcastIndexOnly;

  /// No description provided for @travelXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travelXXXPodcastIndexOnly;

  /// No description provided for @videoGamesXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Video Games'**
  String get videoGamesXXXPodcastIndexOnly;

  /// No description provided for @visualXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Visual'**
  String get visualXXXPodcastIndexOnly;

  /// No description provided for @volleyballXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Volleyball'**
  String get volleyballXXXPodcastIndexOnly;

  /// No description provided for @weatherXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherXXXPodcastIndexOnly;

  /// No description provided for @wildernessXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Wilderness'**
  String get wildernessXXXPodcastIndexOnly;

  /// No description provided for @wrestlingXXXPodcastIndexOnly.
  ///
  /// In en, this message translates to:
  /// **'Wrestling'**
  String get wrestlingXXXPodcastIndexOnly;

  /// No description provided for @removeDownloadEpisode.
  ///
  /// In en, this message translates to:
  /// **'Remove Download'**
  String get removeDownloadEpisode;

  /// No description provided for @downloadEpisode.
  ///
  /// In en, this message translates to:
  /// **'Download Episode'**
  String get downloadEpisode;

  /// Notification message when a download is finished.
  ///
  /// In en, this message translates to:
  /// **'Download finished: {title}'**
  String downloadFinished(String title);

  /// Notification message when a download is cancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled: {title}'**
  String downloadCancelled(String title);

  /// No description provided for @nothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get nothingFound;

  /// No description provided for @podcastFeedIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'This podcast feed is empty.'**
  String get podcastFeedIsEmpty;

  /// No description provided for @podcast.
  ///
  /// In en, this message translates to:
  /// **'Podcast'**
  String get podcast;

  /// No description provided for @episodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get episodes;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @oopsSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong.'**
  String get oopsSomethingWentWrong;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
