import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'utils_platform_interface.dart';

class Utils {
  Future<String?> getPlatformVersion() {
    return UtilsPlatform.instance.getPlatformVersion();
  }

  //HoangLD tạo 1 channel để call native ios
  static const _channelBkav = MethodChannel('com.bkav.utils/bkav_channel');

  static Future<bool> checkBiometricsFaceIdIos() async {
    bool faceId = false;
    if (Platform.isIOS) {
      String checkIos = await _channelBkav.invokeMethod('getBiometricType');
      if (checkIos == "faceID") {
        faceId = true;
      } else {
        faceId = false;
      }
    }
    return faceId;
  }

  static Future<String> checkTestAndroid() async {
    String checkIos = "";
    if (Platform.isAndroid) {
      checkIos = await _channelBkav.invokeMethod('testAndroid');
    }
    return checkIos;
  }

  ///Bkav HoangLD : hiệu ứng chuyển giữa các page khác nhau
  static Route pageRouteBuilder(Widget widget, bool transitions) {
    if (transitions) {
      return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1, 0);
          const end = Offset.zero;
          const curve = Curves.ease;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );
    } else {
      return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => widget);
    }
  }

  ///Bkav TungDV check check man hinh ngang doc de fix loi tai tho tren ios
  static Widget bkavCheckOrientation(BuildContext context, Widget child) {
    return MediaQuery.of(context).orientation == Orientation.portrait
        ? Container(child: child)
        : SafeArea(
            top: false,
            child: child,
          );
  }

  /// HanhNTHe: Lay thong tin dinh danh cua user trong sharePref
  /// co the la userId, userName,... tuy thuoc vao project
  static Future<String> getUserIdInSharePref() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String userId = sharedPreferences.getString("user_identifier") ?? "-1";
    return userId;
  }

  /// HanhNTHe: Lưu thong tin dinh danh cua user trong sharePref
  /// co the la userId, userName,... tuy thuoc vao project
  static Future<void> saveUserIdInSharePref(
      {required String userIdentifier}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("user_identifier", userIdentifier);
  }

  /// Lấy thông tin version hiện tại của app
  static Future<String> getVersionApp() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /**------------------------START---------------------------*/
  /* Logic để launch app tuong ung vs hanh dong -start */

  /// DatNVh open link theo cach mặc định mở browser
  static Future<void> launchInBrowser(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// DatNVh open GoogleMap
  static Future<void> launchMapUrl(String address) async {
    String encodedAddress = Uri.encodeComponent(address);
    String googleMapUrl =
        "https://www.google.com/maps/search/?api=1&query=$encodedAddress";
    String appleMapUrl = "http://maps.apple.com/?q=$encodedAddress";
    Uri googleMapUri = Uri.parse(googleMapUrl);
    Uri appleMapUri = Uri.parse(appleMapUrl);
    if (Platform.isAndroid) {
      try {
        if (await canLaunchUrl(googleMapUri)) {
          await launchUrl(googleMapUri);
        }
      } catch (error) {
        throw ("Cannot launch Google map");
      }
    }
    if (Platform.isIOS) {
      try {
        if (await canLaunchUrl(appleMapUri)) {
          await launchUrl(appleMapUri);
        }
      } catch (error) {
        throw ("Cannot launch Apple map");
      }
    }
  }

  /// DatNVh open phoneCall
  static Future<void> launchPhoneUrl(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw ("the action is not supported.");
    }
  }

  /// DatNVh open email
  static Future<void> launchMailUrl(String email) async {
    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    final Uri emailUrl = Uri(
      scheme: 'mailto',
      path: email,
      query: encodeQueryParameters(
          <String, String>{'subject': "Content", 'body': "Content"}),
    );
    if (await canLaunchUrl(emailUrl)) {
      launchUrl(emailUrl);
    } else {
      throw ("the action is not supported.");
    }
  }

  /* Logic để launch app tuong ung vs hanh dong -end */
  /**-----------------------------------END----------------------------------*/

  /// HanhNTHe: dung de crop anh, return [path] sau khi crop
  static Future<String> cropImage(String imagePath) async {
    String path = "";
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      cropStyle: CropStyle.circle,
      aspectRatioPresets: Platform.isAndroid
          ? [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ]
          : [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio7x5,
              CropAspectRatioPreset.ratio16x9
            ],
    );
    if (croppedFile != null) {
      path = croppedFile.path;
    }
    return path;
  }
}
