import 'package:flutter_test/flutter_test.dart';
import 'package:stats_app/models/coin_model.dart';

void main() {
  group('CoinModel.fromJson', () {
    test('parses complete valid JSON correctly', () {
      final json = {
        'uuid': 'Qwsogvtv82FCd',
        'symbol': 'BTC',
        'name': 'Bitcoin',
        'iconUrl': 'https://example.com/btc.png',
        'price': '65000.50',
        'marketCap': '1280000000000',
        'change': '2.45',
        '24hVolume': '35000000000',
        'rank': 1,
        'sparkline': ['64000', '64500', '65000'],
        'listedAt': 1234567890,
      };

      final coin = CoinModel.fromJson(json);

      expect(coin.uuid, 'Qwsogvtv82FCd');
      expect(coin.symbol, 'BTC');
      expect(coin.name, 'Bitcoin');
      expect(coin.price, '65000.50');
      expect(coin.rank, 1);
      expect(coin.sparkline.length, 3);
      expect(coin.listedAt, true);
    });

    test('handles missing fields with safe defaults', () {
      final json = <String, dynamic>{};

      final coin = CoinModel.fromJson(json);

      expect(coin.uuid, '');
      expect(coin.symbol, '');
      expect(coin.name, '');
      expect(coin.price, null);
      expect(coin.rank, 0);
      expect(coin.sparkline, isEmpty);
      expect(coin.listedAt, false);
    });

    test('parses rank when sent as String instead of int', () {
      final json = {'uuid': 'x', 'symbol': 'X', 'name': 'X Coin', 'rank': '42'};

      final coin = CoinModel.fromJson(json);

      expect(coin.rank, 42);
    });

    test('filters out null values in sparkline list', () {
      final json = {
        'uuid': 'x',
        'symbol': 'X',
        'name': 'X Coin',
        'rank': 1,
        'sparkline': ['100', null, '200', null],
      };

      final coin = CoinModel.fromJson(json);

      expect(coin.sparkline, ['100', '200']);
    });
  });

  group('CoinModel derived getters', () {
    test('priceDouble parses price string correctly', () {
      const coin = CoinModel(
        uuid: 'x',
        symbol: 'X',
        name: 'X',
        rank: 1,
        price: '123.45',
      );

      expect(coin.priceDouble, 123.45);
    });

    test('priceDouble defaults to 0.0 when price is null', () {
      const coin = CoinModel(uuid: 'x', symbol: 'X', name: 'X', rank: 1);

      expect(coin.priceDouble, 0.0);
    });

    test('isPositive is true when change is positive', () {
      const coin = CoinModel(
        uuid: 'x',
        symbol: 'X',
        name: 'X',
        rank: 1,
        change: '5.5',
      );

      expect(coin.isPositive, true);
    });

    test('isPositive is true when change is exactly zero', () {
      const coin = CoinModel(
        uuid: 'x',
        symbol: 'X',
        name: 'X',
        rank: 1,
        change: '0',
      );

      expect(coin.isPositive, true);
    });

    test('isPositive is false when change is negative', () {
      const coin = CoinModel(
        uuid: 'x',
        symbol: 'X',
        name: 'X',
        rank: 1,
        change: '-3.2',
      );

      expect(coin.isPositive, false);
    });

    test('sparklineDoubles converts string list to doubles', () {
      const coin = CoinModel(
        uuid: 'x',
        symbol: 'X',
        name: 'X',
        rank: 1,
        sparkline: ['100.5', '101.0', 'invalid', '102.3'],
      );

      expect(coin.sparklineDoubles, [100.5, 101.0, 0.0, 102.3]);
    });
  });
}
