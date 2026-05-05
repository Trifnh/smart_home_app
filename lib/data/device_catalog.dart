import 'package:flutter/material.dart';

import '../widgets/animated_device_tile.dart';

/// Default MQTT / Firebase device keys aligned with README & Pi scripts.
abstract final class DeviceCatalog {
  static const ids = [
    'light1',
    'light2',
    'light3',
    'fan',
    'ac',
    'heater',
    'air_purifier',
    'humidifier',
    'dehumidifier',
    'curtain',
    'door_lock',
    'sprinkler',
    'alarm',
    'camera',
    'tv',
  ];

  static List<DeviceUi> defaultTiles() => const [
    DeviceUi('light1', 'Đèn Light 1', Icons.light_rounded, 'Chiếu sáng chính'),
    DeviceUi(
      'light2',
      'Đèn Light 2',
      Icons.lightbulb_outline_rounded,
      'Vùng phụ',
    ),
    DeviceUi('light3', 'Đèn Light 3', Icons.lightbulb_rounded, 'Đèn phụ'),
    DeviceUi('fan', 'Quạt', Icons.air_rounded, 'Thông gió'),
    DeviceUi(
      'ac',
      'Máy lạnh / Relay',
      Icons.ac_unit_rounded,
      'HVAC hoặc relay',
    ),
    DeviceUi('heater', 'Máy sưởi', Icons.local_fire_department_rounded, 'Sưởi ấm'),
    DeviceUi('air_purifier', 'Lọc không khí', Icons.air_rounded, 'PM2.5 / purifier'),
    DeviceUi('humidifier', 'Máy tạo ẩm', Icons.water_drop_rounded, 'Tăng độ ẩm'),
    DeviceUi(
      'dehumidifier',
      'Máy hút ẩm',
      Icons.opacity_rounded,
      'Giảm độ ẩm',
    ),
    DeviceUi('curtain', 'Rèm', Icons.blinds_rounded, 'Kéo/mở rèm'),
    DeviceUi('door_lock', 'Khoá cửa', Icons.lock_rounded, 'An ninh cửa'),
    DeviceUi('sprinkler', 'Tưới cây', Icons.grass_rounded, 'Sân vườn'),
    DeviceUi('alarm', 'Còi báo', Icons.notifications_active_rounded, 'Cảnh báo'),
    DeviceUi('camera', 'Camera', Icons.videocam_rounded, 'Quan sát'),
    DeviceUi('tv', 'TV', Icons.tv_rounded, 'Giải trí'),
  ];
}
