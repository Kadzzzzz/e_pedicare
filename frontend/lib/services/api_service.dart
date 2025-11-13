import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service API pour communiquer avec le backend Flask
class ApiService {
  // URL de base du backend (à modifier selon votre configuration)
  static const String baseUrl = 'http://localhost:5000/api';

  // Instance singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Token JWT stocké localement
  String? _jwtToken;

  /// Initialiser le service (charger le token depuis le stockage local)
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwt_token');
  }

  /// Sauvegarder le token JWT
  Future<void> saveToken(String token) async {
    _jwtToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  /// Effacer le token JWT (déconnexion)
  Future<void> clearToken() async {
    _jwtToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  /// Headers HTTP (sans authentification pour le POC)
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        // Pas d'auth pour le POC
      };

  /// Login utilisateur
  ///
  /// Retourne le token JWT en cas de succès
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['access_token'] != null) {
        await saveToken(data['access_token']);
      }
      return data;
    } else {
      throw Exception('Échec de connexion: ${response.body}');
    }
  }

  /// Créer une session vidéo
  ///
  /// [roomName] : Nom de la room LiveKit
  /// [childId] : ID de l'enfant (optionnel pour POC)
  /// Retourne les informations de session incluant le token LiveKit
  Future<Map<String, dynamic>> createVideoSession({
    required String roomName,
    String? childId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/video/create-session'),
      headers: _headers,
      body: jsonEncode({
        'room_name': roomName,
        'child_id': childId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec création session: ${response.body}');
    }
  }

  /// Rejoindre une session vidéo existante
  ///
  /// [roomName] : Nom de la room LiveKit à rejoindre
  /// [participantName] : Nom du participant (ex: "Dr. Martin", "Parent Alice")
  /// Retourne le token LiveKit pour rejoindre la room
  Future<Map<String, dynamic>> joinVideoSession({
    required String roomName,
    required String participantName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/video/join-session'),
      headers: _headers,
      body: jsonEncode({
        'room_name': roomName,
        'participant_name': participantName,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec rejoindre session: ${response.body}');
    }
  }

  /// Obtenir la liste des sessions actives
  Future<List<dynamic>> getActiveSessions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/video/sessions/active'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['sessions'] ?? [];
    } else {
      throw Exception('Échec récupération sessions: ${response.body}');
    }
  }

  /// Terminer une session vidéo
  Future<void> endVideoSession({required String roomName}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/video/end-session'),
      headers: _headers,
      body: jsonEncode({'room_name': roomName}),
    );

    if (response.statusCode != 200) {
      throw Exception('Échec fin de session: ${response.body}');
    }
  }
}
