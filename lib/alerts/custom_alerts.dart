import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
class CustomAlert {
  static void success(BuildContext context, String text) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: text,
    );
  }

  static void error(BuildContext context, String title, String text) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: title,
      text: text,
    );
  }

  static void warning(BuildContext context, String text) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      text: text,
    );
  }

  static void info(BuildContext context, String text) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      text: text,
    );
  }

  static Future confirm(BuildContext context, String text) async {
    return await QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: text,
      confirmBtnText: 'Yes',
      cancelBtnText: 'No',
      confirmBtnColor: Colors.green,
      onConfirmBtnTap: () {
        Navigator.of(context).pop(true); // Return true on Yes
      },
      onCancelBtnTap: () {
        Navigator.of(context).pop(false); // Return false on No
      },
    );
  }

  static void loading(BuildContext context, String title, String text) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: title,
      text: text,
      barrierDismissible: false, // Prevent dismiss on outside tap
    );
  }

  static Future performWithLoading({
    required BuildContext context,
    required String loadingText,
    required Future Function() task,
    String? successMessage,
    String? errorMessage,
  }) async {
    loading(context, 'Loading', loadingText);
    try {
      await task();
      Navigator.pop(context); // Close loading
      if (successMessage != null) {
        success(context, successMessage);
      }
      return true;
    } catch (e) {
      Navigator.pop(context); // Close loading
      if (errorMessage != null) {
        error(context, 'Error', errorMessage);
      }
      return false;
    }
  }
}
