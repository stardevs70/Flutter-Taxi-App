import 'package:flutter/material.dart';

import 'images.dart';

///region App name
const mAppName = 'Eagle Rides';

///endregion

/// region Google map key
const GOOGLE_MAP_API_KEY = 'AIzaSyAA6ivBRPrCrfUNu0NNqKolb6xYg4iOPAQ';

///endregion

///region DomainUrl
// const DOMAIN_URL = 'http://eagleride-limo.com'; // Don't add slash at the end of the url
const DOMAIN_URL = 'http://eagleride-limo.com'; // Don't add slash at the end of the url
///endregion

///region OneSignal Keys
///You have to generate 2 apps on onesignal account one for rider and one for driver
/// Using Eagle Ride limousine App (App ID: 3a28dfa4-63e7-470b-a073-1d9440742561)
const mOneSignalAppIdDriver = '3a28dfa4-63e7-470b-a073-1d9440742561';
const mOneSignalRestKeyDriver = 'os_v2_app_hiun7jdd45dqxidtdwkea5bfmfu6qtwuxs5us5v44wjvgw4nsksn2o7k45k4zjdkwoojcfzhj5aqazszer2ujyyga2bvezdudqkx6iy';
const mOneSignalDriverChannelID = '2ccb7d2c-b3e7-470f-a7c9-f302a7701bef';

const mOneSignalAppIdRider = '3a28dfa4-63e7-470b-a073-1d9440742561';
const mOneSignalRestKeyRider = 'os_v2_app_hiun7jdd45dqxidtdwkea5bfmen2rlaz63gez35og6nizs45ki53j5e47hmiccfydc2igikptib62773ozxh7bdigdu6o5pblb4yl7y';
const mOneSignalRiderChannelID = 'a3fe2762-3657-43dc-8617-114ee6d49ef8';

///endregion

///region firebase configuration
/// User app Firebase project (eagle-rides-11f74)
const projectId = 'eagle-rides-11f74';
const appIdAndroid = '1:643859794339:android:26845cffce8969efadf216';
const apiKeyFirebase = 'AIzaSyD1i1fjZ92pg7XD4LUJNnAj1OoLC-NvNpk';
const messagingSenderId = '643859794339';
const storageBucket = 'eagle-rides-11f74.firebasestorage.app';
const authDomain = "eagle-rides-11f74.firebaseapp.com";

///endregion

///region Currency & country code
const currencySymbol = '\$';
const currencyNameConst = 'usd';
const defaultCountry = 'IN';
const digitAfterDecimal = 2;

///endregion

///region top up default value
const PRESENT_TOP_UP_AMOUNT_CONST = '1000|2000|3000';
const PRESENT_TIP_AMOUNT_CONST = '10|20|30';

///endregion

/// INTRO SCREEN IMAGES ic_walk1,ic_walk2 and ic_walk3
const walkthrough_image_1 = ic_walk1;
const walkthrough_image_2 = ic_walk2;
const walkthrough_image_3 = ic_walk3;

///region url
const mBaseUrl = "$DOMAIN_URL/api/";

///endregion

///region userType
const ADMIN = 'admin';
const DRIVER = 'driver';
const RIDER = 'rider';

///endregion

const PER_PAGE = 15;
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

enum ThemeModes { SystemDefault, Light, Dark }

///region loginType
const LoginTypeApp = 'app';
const LoginTypeGoogle = 'google';
const LoginTypeOTP = 'otp';
const LoginTypeApple = 'apple';

///endregion

///region SharedReference keys
const REMEMBER_ME = 'REMEMBER_ME';
const IS_FIRST_TIME = 'IS_FIRST_TIME';
const IS_LOGGED_IN = 'IS_LOGGED_IN';
const LEFT = 'left';

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
const IS_TIME = 'IS_TIME';
const IS_TIME2 = 'IS_TIME_BID';
const REMAINING_TIME = 'REMAINING_TIME';
const REMAINING_TIME2 = 'REMAINING_TIME_BID';
const LOGIN_TYPE = 'login_type';
const COUNTRY = 'COUNTRY';
const LATITUDE = 'LATITUDE';
const LONGITUDE = 'LONGITUDE';

///endregion

///region Taxi Status
const ACTIVE = 'active';
const IN_ACTIVE = 'inactive';
const PENDING = 'pending';
const BANNED = 'banned';
const REJECT = 'reject';

///endregion

///region Wallet keys
const CREDIT = 'credit';
const DEBIT = 'debit';
const OTHERS = 'Others';

///endregion

///region paymentType
const PAYMENT_TYPE_STRIPE = 'stripe';
const PAYMENT_TYPE_RAZORPAY = 'razorpay';
const PAYMENT_TYPE_PAYSTACK = 'paystack';
const PAYMENT_TYPE_FLUTTERWAVE = 'flutterwave';
const PAYMENT_TYPE_PAYPAL = 'paypal';
const PAYMENT_TYPE_PAYTABS = 'paytabs';
const PAYMENT_TYPE_MERCADOPAGO = 'mercadopago';
const PAYMENT_TYPE_PAYTM = 'paytm';
const PAYMENT_TYPE_MYFATOORAH = 'myfatoorah';

const stripeURL = 'https://api.stripe.com/v1/payment_intents';

///endregion

var errorThisFieldRequired = 'This field is required';

///region Ride Status
const UPCOMING = 'upcoming';
const NEW_RIDE_REQUESTED = 'pending';
const ACCEPTED = 'accepted';
const ASSIGN_DRIVER = 'assign_driver';
const BID_ACCEPTED = 'bid_accepted';
const ARRIVING = 'arriving';
const ARRIVED = 'arrived';
const IN_PROGRESS = 'in_progress';
const CANCELED = 'cancelled';
const COMPLETED = 'completed';
const SUCCESS = 'payment_status_message';
const AUTO = 'auto';
const COMPLAIN_COMMENT = "complaintcomment";

///endregion

///fix Decimal
const fixedDecimal = digitAfterDecimal;

///region
const CHARGE_TYPE_FIXED = 'fixed';
const CHARGE_TYPE_PERCENTAGE = 'percentage';
const CASH_WALLET = 'cash_wallet';
const CASH = 'cash';
const MALE = 'male';
const FEMALE = 'female';
const OTHER = 'other';
const WALLET = 'wallet';
const ONLINE = 'online';
const DISTANCE_TYPE_KM = 'km';
const DISTANCE_TYPE_MILE = 'mile';

/// This is for Delivery Type Booking Identify Used and for Taxi Booking Its "BOOK_RIDE"
const TRANSPORT = "transport";
const BOOK_RIDE = "book_ride";
const BOTH = "both";

///endregion

///region app setting key
const CLOCK = 'clock';
const PRESENT_TOPUP_AMOUNT = 'preset_topup_amount';
const PRESENT_TIP_AMOUNT = 'preset_tip_amount';
const RIDE_FOR_OTHER = 'RIDE_FOR_OTHER';
const IS_MULTI_DROP = 'RIDE_MULTIPLE_DROP_LOCATION';
const RIDE_IS_SCHEDULE_RIDE = 'RIDE_IS_SCHEDULE_RIDE';
const ACTIVE_SERVICES = 'ACTIVE_SERVICE_TYPE';
const IS_BID_ENABLE = 'is_bidding';
const MAX_TIME_FOR_RIDER_MINUTE = 'max_time_for_find_drivers_for_regular_ride_in_minute';
const MAX_TIME_FOR_DRIVER_SECOND = 'ride_accept_decline_duration_for_driver_in_second';
const MIN_AMOUNT_TO_ADD = 'min_amount_to_add';
const MAX_AMOUNT_TO_ADD = 'max_amount_to_add';

///endregion

///region FireBase Collection Name
const MESSAGES_COLLECTION = "RideTalk";
const RIDE_CHAT = "RideTalkHistory";
const RIDE_COLLECTION = 'rides';
const USER_COLLECTION = "users";

///endregion

const IS_ENTER_KEY = "IS_ENTER_KEY";
const SELECTED_WALLPAPER = "SELECTED_WALLPAPER";
const PER_PAGE_CHAT_COUNT = 50;
const TEXT = "TEXT";
const IMAGE = "IMAGE";
const VIDEO = "VIDEO";
const AUDIO = "AUDIO";
const FIXED_CHARGES = "fixed_charges";
const MIN_DISTANCE = "min_distance";
const MIN_WEIGHT = "min_weight";
const PER_DISTANCE_CHARGE = "per_distance_charges";
const PER_WEIGHT_CHARGE = "per_weight_charges";
const PAID = 'paid';
const PAYMENT_PENDING = 'pending';
const PAYMENT_FAILED = 'failed';
const PAYMENT_PAID = 'paid';
const THEME_MODE_INDEX = 'theme_mode_index';
const CHANGE_MONEY = 'CHANGE_MONEY';
const CHANGE_LANGUAGE = 'CHANGE_LANGUAGE';
List<String> rtlLanguage = ['ar', 'ur'];

enum MessageType { TEXT, IMAGE, VIDEO, AUDIO }

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

var errorSomethingWentWrong = 'Something Went Wrong';
var rideNotFound = "Ride Not Detected";

var demoEmail = 'joy58@gmail.com';
const mRazorDescription = mAppName;
const mStripeIdentifier = 'IN';

const ORDER_CREATED = 'create';
const ORDER_ACCEPTED = 'accepted';
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

/// Trip type list - Original options restored per client request
const tripTypeList = [
  tripTypeRegular,
  tripTypeAirportPickup,
  tripTypeAirportDropoff,
  tripTypeZoneWise,
  tripTypeZoneToAirport,
  tripTypeAirportToZone,
];

const tripTypeRegular = 'Regular';
const tripTypeAirportPickup = 'Airport Pickup';
const tripTypeAirportDropoff = 'Airport Dropoff';
const tripTypeZoneWise = 'Zone Wise';
const tripTypeZoneToAirport = 'Zone to Airport';
const tripTypeAirportToZone = 'Airport to Zone';

/// Simplified Airport constant (kept for compatibility)
const tripTypeAirport = 'Airport';

double? defaultInkWellRadius;
Color? defaultInkWellSplashColor;
Color? defaultInkWellHoverColor;
Color? defaultInkWellHighlightColor;
