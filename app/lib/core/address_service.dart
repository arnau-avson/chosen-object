import 'package:flutter/foundation.dart';
import '../models/address.dart';
import 'api_client.dart';

class AddressService extends ChangeNotifier {
  static final AddressService _instance = AddressService._();
  static AddressService get instance => _instance;
  AddressService._();

  List<Address> _addresses = [];

  List<Address> get addresses => List.unmodifiable(_addresses);

  Address? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return null;
    }
  }

  // ── Backend integration ─────────────────────────────────────

  Future<void> loadFromBackend() async {
    try {
      final data = await ApiClient.instance.get('/addresses');
      _addresses =
          (data as List).map((j) => Address.fromJson(j as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (_) {
      // Offline — keep local state
    }
  }

  Future<void> addAddress(Address address) async {
    // Optimistic local add
    _addresses.add(address);
    notifyListeners();

    try {
      final data = await ApiClient.instance.post('/addresses', address.toJson());
      // Replace optimistic entry with the one that has a real id
      final saved = Address.fromJson(data);
      _addresses[_addresses.length - 1] = saved;
      // If it was auto-set as default (first address), refresh the whole list
      if (saved.isDefault && _addresses.length == 1) {
        _addresses = [saved];
      }
      notifyListeners();
    } catch (_) {
      // Keep optimistic state
    }
  }

  Future<void> updateAddress(int id, Address address) async {
    // Optimistic local update
    final idx = _addresses.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _addresses[idx] = address;
      notifyListeners();
    }

    try {
      final data = await ApiClient.instance.put('/addresses/$id', address.toJson());
      if (idx != -1) {
        _addresses[idx] = Address.fromJson(data);
        notifyListeners();
      }
    } catch (_) {
      // Keep optimistic state
    }
  }

  Future<void> deleteAddress(int id) async {
    final idx = _addresses.indexWhere((a) => a.id == id);
    Address? removed;
    if (idx != -1) {
      removed = _addresses.removeAt(idx);
      notifyListeners();
    }

    try {
      await ApiClient.instance.delete('/addresses/$id');
      // Reload to get updated defaults
      await loadFromBackend();
    } catch (_) {
      // Revert on failure
      if (removed != null && idx != -1) {
        _addresses.insert(idx, removed);
        notifyListeners();
      }
    }
  }

  Future<void> setDefault(int id) async {
    // Optimistic local update
    _addresses = _addresses.map((a) => a.copyWith(isDefault: a.id == id)).toList();
    notifyListeners();

    try {
      await ApiClient.instance.patch('/addresses/$id/default');
    } catch (_) {
      // Keep optimistic state
    }
  }

  void setDefaultByIndex(int index) {
    if (index < 0 || index >= _addresses.length) return;
    final address = _addresses[index];

    if (address.id != null) {
      setDefault(address.id!);
      return;
    }

    _addresses = List.generate(_addresses.length, (i) {
      return _addresses[i].copyWith(isDefault: i == index);
    });
    notifyListeners();
  }

  Future<void> deleteAddressByIndex(int index) async {
    if (index < 0 || index >= _addresses.length) return;
    final address = _addresses[index];

    if (address.id != null) {
      await deleteAddress(address.id!);
      return;
    }

    _addresses.removeAt(index);
    notifyListeners();
  }

  /// Re-add an address (used for undo after delete)
  Future<void> reAddAddress(Address address) async {
    _addresses.add(address);
    notifyListeners();

    try {
      final data = await ApiClient.instance.post('/addresses', address.toJson());
      final saved = Address.fromJson(data);
      _addresses[_addresses.length - 1] = saved;

      // If original was default, restore default status
      if (address.isDefault && saved.id != null) {
        await setDefault(saved.id!);
      }
      notifyListeners();
    } catch (_) {
      // Keep optimistic state
    }
  }
}
