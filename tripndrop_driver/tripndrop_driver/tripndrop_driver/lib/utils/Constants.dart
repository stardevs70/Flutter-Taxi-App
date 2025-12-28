import 'package:flutter/material.dart';

///region App name
const mAppName = 'Eagle Rides Driver';

///endregion

///region DomainUrl
// const DOMAIN_URL = 'http://eagleride-limo.com'; // Don't add slash at the end of the url
const DOMAIN_URL = 'http://eagleride-limo.com'; // Don't add slash at the end of the url
///endregion

///region Google map key
const GOOGLE_MAP_API_KEY = 'AIzaSyAA6ivBRPrCrfUNu0NNqKolb6xYg4iOPAQ';

///endregion

///region Currency & country code
const currencySymbol = '\$';
const currencyNameConst = 'usd';
const defaultCountry = 'IN';

///endregion

///region decimal
const digitAfterDecimal = 2;

///endregion

///region OneSignal Keys
///You have to generate 2 apps on onesignal account one for Rider and one for Driver
///region OneSignal Keys
///You have to generate 2 apps on onesignal account one for rider and one for driver
const mOneSignalAppIdDriver = 'e360668f-ccaa-4ab3-990c-b736989901f4';
//const mOneSignalAppIdDriver = 'a700aa40-4dda-41e9-9b38-bc98a4c52df4';
const mOneSignalRestKeyDriver = 'os_v2_app_4nqgnd6mvjflhgimw43jrgib6r36lfgqemuev6ftxixiaptbhqwplt7pnrqabgnp6l2tfoisriklrepln7fssvxu4562iuj6suhkkfq';
//const mOneSignalRestKeyDriver = 'os_v2_app_u4akuqcn3ja6tgzyxsmkjrjn6r5yutiybmlu2w4274nu3sxbuc4enjjxddxcotbzyhaxza6oe3noppg2eq2u2f4pafg6o32wzomx3oi';
const mOneSignalDriverChannelID = '2ccb7d2c-b3e7-470f-a7c9-f302a7701bef';

const mOneSignalAppIdRider = 'e360668f-ccaa-4ab3-990c-b736989901f4';
const mOneSignalRestKeyRider = 'os_v2_app_4nqgnd6mvjflhgimw43jrgib6r36lfgqemuev6ftxixiaptbhqwplt7pnrqabgnp6l2tfoisriklrepln7fssvxu4562iuj6suhkkfq';
const mOneSignalRiderChannelID = 'a3fe2762-3657-43dc-8617-114ee6d49ef8';

///endregion

///region firebase configuration
/// FIREBASE VALUES FOR ANDROID APP
const projectId = 'eagle-rides-driver';
const appIdAndroid = '1:437609761245:android:57e88c8e01be9b22808e34';
const apiKeyFirebase = 'AIzaSyD49uRizy0KNKRdZVWB1G1jAFTSd6R4Sc4';
const messagingSenderId = '437609761245';
const storageBucket = 'eagle-rides-driver.firebasestorage.app';
const authDomain = "eagle-rides-driver.firebaseapp.com";

///endregion

///region top up default value
const PRESENT_TOP_UP_AMOUNT_CONST = '1000|2000|3000';
const PRESENT_TIP_AMOUNT_CONST = '10|20|30';

///endregion

///region url
var mBaseUrl = "$DOMAIN_URL/api/";

///endregion

///region login type
const LoginTypeGoogle = 'google';
const LoginTypeOTP = 'mobile';
const LoginTypeApple = 'apple';

///endregion

///region error field
var errorThisFieldRequired = 'This field is required';
var errorSomethingWentWrong = 'Something Went Wrong';

///endregion

///region SharedReference keys
const REMEMBER_ME = 'REMEMBER_ME';
const IS_FIRST_TIME = 'IS_FIRST_TIME';
const IS_LOGGED_IN = 'IS_LOGGED_IN';
const ON_RIDE_MODEL = 'ON_RIDE_MODEL';
const IS_TIME2 = 'IS_TIME2';
const USER_ID = 'USER_ID';
const FIRST_NAME = 'FIRST_NAME';
const OTP_STATUS = 'OTP_STATUS';
const LAST_NAME = 'LAST_NAME';
const TOKEN = 'TOKEN';
const USER_EMAIL = 'USER_EMAIL';
const USER_TOKEN = 'USER_TOKEN';
const USER_PROFILE_PHOTO = 'USER_PROFILE_PHOTO';
const USER_TYPE = 'USER_TYPE';
const USER_NAME = 'USER_NAME';
const USER_PASSWORD = 'USER_PASSWORD';
const USER_ADDRESS = 'USER_ADDRESS';
const STATUS = 'STATUS';
const CONTACT_NUMBER = 'CONTACT_NUMBER';
const PLAYER_ID = 'PLAYER_ID';
const UID = 'UID';
const ADDRESS = 'ADDRESS';
const IS_OTP = 'IS_OTP';
const IS_GOOGLE = 'IS_GOOGLE';
const GENDER = 'GENDER';
const IS_ONLINE = 'IS_ONLINE';
const IS_Verified_Driver = 'is_verified_driver';
const LATITUDE = 'LATITUDE';
const LONGITUDE = 'LONGITUDE';

///endregion

///region user roles
const ADMIN = 'admin';
const DRIVER = 'driver';
const RIDER = 'rider';

///endregion

///region Taxi Status
const IN_ACTIVE = 'inactive';
const PENDING = 'pending';
const BANNED = 'banned';
const REJECT = 'reject';

///endregion

///region Wallet keys
const CREDIT = 'credit';
const DEBIT = 'debit';

///endregion

///region payment
const PAYMENT_TYPE_STRIPE = 'stripe';
const PAYMENT_TYPE_RAZORPAY = 'razorpay';
const PAYMENT_TYPE_PAYSTACK = 'paystack';
const PAYMENT_TYPE_FLUTTERWAVE = 'flutterwave';
const PAYMENT_TYPE_PAYPAL = 'paypal';
const PAYMENT_TYPE_PAYTABS = 'paytabs';
const PAYMENT_TYPE_MERCADOPAGO = 'mercadopago';
const PAYMENT_TYPE_PAYTM = 'paytm';
const PAYMENT_TYPE_MYFATOORAH = 'myfatoorah';
const CASH = 'cash';
const Wallet = 'wallet';
const ONLINE = 'online';

/// This is for Delivery Type Booking Identify Used and for Taxi Booking Its "BOOK_RIDE"
const TRANSPORT = "transport";
const BOOK_RIDE = "book_ride";
const BOTH = "both";

const stripeURL = 'https://api.stripe.com/v1/payment_intents';

const mRazorDescription = mAppName;
const mStripeIdentifier = defaultCountry;

///endregion

///region Rides Status
const UPCOMING = 'upcoming';
const NEW_RIDE_REQUESTED = 'pending';

/// const NEW_RIDE_REQUESTED = 'new_ride_requested';
const BID_ACCEPTED = 'bid_accepted';
const BID_REJECTED = 'bid_rejected';
const ACCEPTED = 'accepted';
const ASSIGN_DRIVER = 'assign_driver';
const ARRIVING = 'arriving';
const ACTIVE = 'active';
const ARRIVED = 'arrived';
const IN_PROGRESS = 'in_progress';
const CANCELED = 'cancelled';
const COMPLETED = 'completed';
const COMPLAIN_COMMENT = "complaintcomment";

/// Eagle Rides Development Plan - New Trip Statuses (Section 6)
const TRIP_REQUESTED = 'REQUESTED';
const TRIP_ACCEPTED = 'ACCEPTED';
const TRIP_ARRIVED = 'ARRIVED';
const TRIP_STARTED = 'STARTED';
const TRIP_COMPLETED = 'COMPLETED';
const TRIP_CANCELED = 'CANCELED';
const TRIP_NO_DRIVER_FOUND = 'NO_DRIVER_FOUND';

/// Trip Types
const TRIP_TYPE_STANDARD = 'STANDARD';
const TRIP_TYPE_HOURLY = 'HOURLY';

/// Cancellation party constants
const CANCELED_BY_RIDER = 'RIDER';
const CANCELED_BY_DRIVER = 'DRIVER';
const CANCELED_BY_BACKEND = 'BACKEND';
const CANCELED_BY_ADMIN = 'ADMIN';

/// Offer Status
const OFFER_OFFERED = 'OFFERED';
const OFFER_ACCEPTED = 'ACCEPTED';
const OFFER_REJECTED = 'REJECTED';
const OFFER_EXPIRED = 'EXPIRED';

/// Priority Tier
const PRIORITY_TIER_PRIORITY = 'PRIORITY';
const PRIORITY_TIER_GENERAL = 'GENERAL';

///endregion

///region FireBase Collection Name
const MESSAGES_COLLECTION = "RideTalk";

/// const MESSAGES_COLLECTION = "messages";
const RIDE_CHAT = "RideTalkHistory";
const RIDE_COLLECTION = 'rides';

const USER_COLLECTION = "users";

/// Eagle Rides Development Plan - New Collections (Section 4)
const TRIPS_COLLECTION = 'trips';
const DRIVERS_COLLECTION = 'drivers';
const TRIP_REQUESTS_COLLECTION = 'trip_requests';
const OFFERS_COLLECTION = 'offers';
const PRICING_COLLECTION = 'pricing';
const TRIP_EVENTS_COLLECTION = 'trip_events';
const TRACK_COLLECTION = 'track';
const EXTENSIONS_COLLECTION = 'extensions';

/// RTDB Paths
const DRIVERS_LOCATIONS_PATH = 'drivers_locations';

///endregion

///region keys
const IS_ENTER_KEY = "IS_ENTER_KEY";
const SELECTED_WALLPAPER = "SELECTED_WALLPAPER";
const PER_PAGE_CHAT_COUNT = 50;
const PAYMENT_PENDING = 'pending';
const PAYMENT_FAILED = 'failed';
const PAYMENT_PAID = 'paid';
const THEME_MODE_INDEX = 'theme_mode_index';
const CHANGE_LANGUAGE = 'CHANGE_LANGUAGE';
const CHANGE_MONEY = 'CHANGE_MONEY';
const LOGIN_TYPE = 'login_type';

const TEXT = "TEXT";
const IMAGE = "IMAGE";

const VIDEO = "VIDEO";
const AUDIO = "AUDIO";

const FIXED_CHARGES = "fixed_charges";
const MIN_DISTANCE = "min_distance";
const MIN_WEIGHT = "min_weight";
const PER_DISTANCE_CHARGE = "per_distance_charges";
const PER_WEIGHT_CHARGE = "per_weight_charges";

const CHARGE_TYPE_FIXED = 'fixed';
const CHARGE_TYPE_PERCENTAGE = 'percentage';
const CASH_WALLET = 'cash_wallet';
const MALE = 'male';
const FEMALE = 'female';
const OTHER = 'other';
const LEFT = 'left';

///endregion

///region app setting key
const CLOCK = 'clock';
const PRESENT_TOPUP_AMOUNT = 'preset_topup_amount';
const PRESENT_TIP_AMOUNT = 'preset_tip_amount';
const MAX_TIME_FOR_RIDER_MINUTE = 'max_time_for_find_drivers_for_regular_ride_in_minute';
const MAX_TIME_FOR_DRIVER_SECOND = 'ride_accept_decline_duration_for_driver_in_second';
const MIN_AMOUNT_TO_ADD = 'min_amount_to_add';
const MAX_AMOUNT_TO_ADD = 'max_amount_to_add';
const APPLY_ADDITIONAL_FEE = 'apply_additional_fee';
const DOC_REJECTED = 'document_approved';
const DOC_APPROVED = 'document_rejected';
const RIDE_DRIVER_CAN_REVIEW = 'RIDE_DRIVER_CAN_REVIEW';
const FLIGHT_TRACKING_ENABLE = 'FLIGHT_TRACKING_ENABLE_TYPE';

///endregion

///region chat
List<String> rtlLanguage = ['ar', 'ur'];

enum MessageType {
  TEXT,
  IMAGE,
  VIDEO,
  AUDIO,
}

extension MessageExtension on MessageType {
  String? get name {
    switch (this) {
      case MessageType.TEXT:
        return 'TEXT';
      case MessageType.IMAGE:
        return 'IMAGE';
      case MessageType.VIDEO:
        return 'VIDEO';
      case MessageType.AUDIO:
        return 'AUDIO';
    }
  }
}

///endregion

///region const values
const passwordLengthGlobal = 8;
const defaultRadius = 30.0;
const defaultSmallRadius = 6.0;

const textPrimarySizeGlobal = 16.00;
const textBoldSizeGlobal = 16.00;
const textSecondarySizeGlobal = 14.00;

double tabletBreakpointGlobal = 600.0;
double desktopBreakpointGlobal = 720.0;
double statisticsItemWidth = 230.0;
double defaultAppButtonElevation = 4.0;

bool enableAppButtonScaleAnimationGlobal = true;
int? appButtonScaleAnimationDurationGlobal;
ShapeBorder? defaultAppButtonShapeBorder;

var customDialogHeight = 140.0;
var customDialogWidth = 220.0;
const PER_PAGE = 50;

///endregion

const ORDER_CREATED = 'create';
const ORDER_ACCEPTED = 'active';
const ORDER_CANCELLED = 'cancelled';
const ORDER_DELAYED = 'delayed';
const ORDER_ASSIGNED = 'courier_assigned';
const ORDER_ARRIVED = 'courier_arrived';
const ORDER_PICKED_UP = 'courier_picked_up';
const ORDER_DELIVERED = 'completed';
const ORDER_DRAFT = 'draft';
const ORDER_DEPARTED = 'courier_departed';
const ORDER_TRANSFER = 'courier_transfer';
const ORDER_PAYMENT = 'payment_status_message';
const ORDER_FAIL = 'failed';
const ORDER_SHIPPED = 'shipped';
const ORDER_PICK_UP_TIME = 'pickup_time';
const ORDER_DELIVERY_TIME = 'delivery_time';

const CURRENCY_POSITION_LEFT = 'left';
const CURRENCY_POSITION_RIGHT = 'right';
const TODAY_ORDER = 'todayOrder';
const REMAINING_ORDER = 'remainingOrder';
const COMPLETED_ORDER = 'completedOrder';
const INPROGRESS_ORDER = 'inProgressOrder';
const TOTAL_EARNING = 'commission';
const WALLET_BALANCE = 'walletBalance';
const PENDING_WITHDRAW_REQUEST = 'pendingWithdReq';
const COMPLETED_WITHDRAW_REQUEST = 'completedWithReq';

const pendingColor = Color(0xFFEA2F2F);
const acceptColor = Color(0xFF00968A);
const on_goingColor = Color(0xFFFD6922);
const in_progressColor = Color(0xFFFD6922);
const holdColor = Color(0xFFFFBD49);
const cancelledColor = Color(0xffFF0303);
const rejectedColor = Color(0xFF8D0E06);
const failedColor = Color(0xFFC41520);
const completedColor = Color(0xFF3CAE5C);
const defaultStatusColor = Color(0xFF3CAE5C);
const WaitingStatusColor = Color(0xFFDBC106);
const pendingApprovalColorColor = Color(0xFFFD6922);
const CreatedColorColor = Color(0xFF0088FF);
const dialogColor = Color(0xff1D1D1D);

double? defaultInkWellRadius;
Color? defaultInkWellSplashColor;
Color? defaultInkWellHoverColor;
Color? defaultInkWellHighlightColor;
