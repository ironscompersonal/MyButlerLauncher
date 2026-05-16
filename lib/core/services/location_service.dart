import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  /// 現在の位置情報を取得（権限チェック含む）
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 位置情報サービスが有効かチェック
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  /// Googleマップを開く
  Future<bool> openGoogleMaps({required String query, String mode = 'search'}) async {
    Uri url;
    
    if (mode == 'directions') {
      // 経路検索モード
      url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(query)}&travelmode=driving');
    } else {
      // 周辺検索モード
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    }

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Googleマップを開くことができませんでした。';
    }
  }
}
