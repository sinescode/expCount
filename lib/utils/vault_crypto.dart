import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// AES-256-CBC encryption for hidden/secret transaction fields.
/// The key is derived from the user's vault PIN via SHA-256.
/// If no PIN is set, a static app-salt key is used (still better than plain text).
///
/// Fields encrypted for hidden transactions:
///   title, category, type, note, tag, paymentMethod, dateTime
/// Fields left plain (so analytics can still count money):
///   id, amount, isHidden, isRecurring
///
/// Fields encrypted for hidden debts:
///   personName, note
/// Fields left plain:
///   id, totalAmount, paidAmount, type, status, createdAt, dueDate
class VaultCrypto {
  static const _appSalt = 'ExpCount_Vault_2024_SecretSalt!@#';

  late final enc.Encrypter _encrypter;
  late final enc.Key _key;

  VaultCrypto({String? pin}) {
    final source = pin ?? _appSalt;
    // Derive 32-byte key from PIN via SHA-256
    final keyBytes = sha256.convert(utf8.encode(source)).bytes;
    _key = enc.Key(Uint8List.fromList(keyBytes));
    _encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
  }

  /// Encrypt a string. Returns "iv:ciphertext" as base64.
  String encrypt(String plainText) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    // Pack as base64(iv) + ':' + base64(ciphertext)
    final ivB64 = base64.encode(iv.bytes);
    return '$ivB64:${encrypted.base64}';
  }

  /// Decrypt a "iv:ciphertext" string. Returns original text or '???' on failure.
  String decrypt(String packed) {
    try {
      final parts = packed.split(':');
      if (parts.length < 2) return packed; // not encrypted, return as-is
      final iv = enc.IV(Uint8List.fromList(base64.decode(parts[0])));
      final cipherB64 = parts.sublist(1).join(':'); // in case ciphertext had ':'
      final encrypted = enc.Encrypted.fromBase64(cipherB64);
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {
      return '🔒 [encrypted]';
    }
  }

  /// Safely try to detect if a string looks encrypted (iv:ciphertext pattern).
  static bool isEncrypted(String? value) {
    if (value == null) return false;
    final parts = value.split(':');
    if (parts.length < 2) return false;
    try {
      final ivBytes = base64.decode(parts[0]);
      return ivBytes.length == 16;
    } catch (_) {
      return false;
    }
  }
}
