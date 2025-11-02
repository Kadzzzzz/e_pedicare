import requests
import json

BASE_URL = "http://localhost:5000"

# Couleurs pour le terminal
class Color:
    GREEN = '\033[92m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    YELLOW = '\033[93m'
    END = '\033[0m'

def print_test(name):
    print(f"\n{Color.BLUE}{'='*50}")
    print(f"TEST: {name}")
    print(f"{'='*50}{Color.END}")

def print_success(message):
    print(f"{Color.GREEN}✅ {message}{Color.END}")

def print_error(message):
    print(f"{Color.RED}❌ {message}{Color.END}")

def print_info(message):
    print(f"{Color.YELLOW}ℹ️  {message}{Color.END}")

# Variables globales
token = None
admin_token = None

def test_1_index():
    """Test de la route index"""
    print_test("1. Route index /api/")

    try:
        response = requests.get(f"{BASE_URL}/api/")

        if response.status_code == 200:
            print_success("Route index accessible")
            data = response.json()
            print_info(f"Message: {data['message']}")
            print_info(f"Version: {data['version']}")
            print_info(f"Status: {data['status']}")
            return True
        else:
            print_error("Route index inaccessible")
            return False
    except Exception as e:
        print_error(f"Impossible de se connecter au serveur: {e}")
        print_info("Vérifiez que le serveur est démarré: python app.py")
        return False

def test_2_health():
    """Test de la route health check"""
    print_test("2. Health check /api/health")

    try:
        response = requests.get(f"{BASE_URL}/api/health")

        if response.status_code == 200:
            print_success("Health check OK")
            data = response.json()
            print_info(f"Status: {data['status']}")
            print_info(f"Message: {data['message']}")
            return True
        else:
            print_error("Health check échoué")
            return False
    except Exception as e:
        print_error(f"Erreur: {e}")
        return False

def test_3_register_parent():
    """Créer un compte parent"""
    print_test("3. Créer un compte parent")

    data = {
        "email": "test_parent@test.fr",
        "password": "password123",
        "role": "parent"
    }

    response = requests.post(f"{BASE_URL}/api/auth/register", json=data)

    if response.status_code == 201:
        print_success("Compte parent créé avec succès")
        user = response.json()['user']
        print_info(f"Email: {user['email']}, Rôle: {user['role']}")
        return True
    elif response.status_code == 409:
        print_info("Compte existe déjà (normal si déjà testé)")
        return True
    else:
        print_error(f"Échec de la création: {response.json()}")
        return False

def test_4_register_expert():
    """Créer un compte expert"""
    print_test("4. Créer un compte expert")

    data = {
        "email": "test_expert@test.fr",
        "password": "password123",
        "role": "expert"
    }

    response = requests.post(f"{BASE_URL}/api/auth/register", json=data)

    if response.status_code == 201:
        print_success("Compte expert créé avec succès")
        user = response.json()['user']
        print_info(f"Email: {user['email']}, Rôle: {user['role']}")
        return True
    elif response.status_code == 409:
        print_info("Compte existe déjà (normal si déjà testé)")
        return True
    else:
        print_error(f"Échec de la création: {response.json()}")
        return False

def test_5_register_invalid_role():
    """Créer un compte avec un rôle invalide"""
    print_test("5. Créer un compte avec rôle invalide")

    data = {
        "email": "test_invalid@test.fr",
        "password": "password123",
        "role": "hacker"
    }

    response = requests.post(f"{BASE_URL}/api/auth/register", json=data)

    if response.status_code == 400:
        print_success("Rôle invalide refusé (normal)")
        print_info(f"Message: {response.json()['message']}")
        return True
    else:
        print_error("Rôle invalide accepté (problème!)")
        return False

def test_6_register_missing_fields():
    """Créer un compte sans tous les champs"""
    print_test("6. Créer un compte sans email")

    data = {
        "password": "password123",
        "role": "parent"
    }

    response = requests.post(f"{BASE_URL}/api/auth/register", json=data)

    if response.status_code == 400:
        print_success("Champs manquants détectés (normal)")
        print_info(f"Message: {response.json()['message']}")
        return True
    else:
        print_error("Champs manquants non détectés (problème!)")
        return False

def test_7_login_parent():
    """Se connecter avec le compte parent"""
    global token
    print_test("7. Connexion parent")

    data = {
        "email": "test_parent@test.fr",
        "password": "password123"
    }

    response = requests.post(f"{BASE_URL}/api/auth/login", json=data)

    if response.status_code == 200:
        print_success("Connexion parent réussie")
        token = response.json()['access_token']
        user = response.json()['user']
        print_info(f"Email: {user['email']}, Rôle: {user['role']}")
        print_info(f"Token reçu: {token[:30]}...")
        return True
    else:
        print_error(f"Échec de la connexion: {response.json()}")
        return False

def test_8_login_wrong_password():
    """Connexion avec mauvais mot de passe"""
    print_test("8. Connexion avec mauvais mot de passe")

    data = {
        "email": "test_parent@test.fr",
        "password": "MAUVAIS_PASSWORD"
    }

    response = requests.post(f"{BASE_URL}/api/auth/login", json=data)

    if response.status_code == 401:
        print_success("Mauvais mot de passe refusé (normal)")
        print_info(f"Message: {response.json()['message']}")
        return True
    else:
        print_error("Le mauvais mot de passe a été accepté (problème!)")
        return False

def test_9_login_nonexistent_user():
    """Connexion avec utilisateur inexistant"""
    print_test("9. Connexion avec utilisateur inexistant")

    data = {
        "email": "nexistepas@test.fr",
        "password": "password123"
    }

    response = requests.post(f"{BASE_URL}/api/auth/login", json=data)

    if response.status_code == 401:
        print_success("Utilisateur inexistant refusé (normal)")
        print_info(f"Message: {response.json()['message']}")
        return True
    else:
        print_error("Utilisateur inexistant accepté (problème!)")
        return False

def test_10_profile_with_token():
    """Accéder au profil avec token"""
    print_test("10. Accéder au profil avec token")

    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/api/auth/profile", headers=headers)

    if response.status_code == 200:
        print_success("Profil récupéré")
        user = response.json()['user']
        jwt_data = response.json()['jwt_data']
        print_info(f"Email: {user['email']}, Rôle: {user['role']}")
        print_info(f"JWT Role: {jwt_data['role']}, User ID: {jwt_data['user_id']}")
        return True
    else:
        print_error(f"Échec: {response.json()}")
        return False

def test_11_profile_without_token():
    """Accéder au profil SANS token"""
    print_test("11. Accéder au profil SANS token")

    response = requests.get(f"{BASE_URL}/api/auth/profile")

    if response.status_code == 401:
        print_success("Accès refusé sans token (normal)")
        print_info(f"Message: {response.json()['message']}")
        return True
    else:
        print_error("Accès autorisé sans token (problème!)")
        return False

def test_12_profile_invalid_token():
    """Accéder au profil avec token invalide"""
    print_test("12. Accéder au profil avec token invalide")

    headers = {"Authorization": "Bearer TOKEN_INVALIDE_123456"}
    response = requests.get(f"{BASE_URL}/api/auth/profile", headers=headers)

    if response.status_code == 401:
        print_success("Token invalide refusé (normal)")
        print_info(f"Message: {response.json()['message']}")
        return True
    else:
        print_error("Token invalide accepté (problème!)")
        return False

def test_13_check_auth_with_token():
    """Vérifier l'authentification avec token"""
    print_test("13. Check auth avec token")

    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/api/auth/check", headers=headers)

    if response.status_code == 200:
        print_success("Authentification vérifiée")
        data = response.json()
        print_info(f"Authenticated: {data['authenticated']}")
        print_info(f"Email: {data['email']}, Role: {data['role']}")
        return True
    else:
        print_error(f"Échec: {response.json()}")
        return False

def test_14_check_auth_without_token():
    """Vérifier l'authentification sans token"""
    print_test("14. Check auth sans token")

    response = requests.get(f"{BASE_URL}/api/auth/check")

    if response.status_code == 401:
        print_success("Vérification refusée sans token (normal)")
        print_info(f"Message: {response.json()['message']}")
        return True
    else:
        print_error("Vérification acceptée sans token (problème!)")
        return False

def test_15_login_admin():
    """Connexion admin"""
    global admin_token
    print_test("15. Connexion avec compte admin")

    data = {
        "email": "admin@epedicare.fr",
        "password": "admin123"
    }

    response = requests.post(f"{BASE_URL}/api/auth/login", json=data)

    if response.status_code == 200:
        print_success("Connexion admin réussie")
        admin_token = response.json()['access_token']
        user = response.json()['user']
        print_info(f"Email: {user['email']}, Rôle: {user['role']}")
        return True
    else:
        print_error("Échec de connexion admin")
        return False

def test_16_admin_profile():
    """Profil admin"""
    print_test("16. Profil admin")

    headers = {"Authorization": f"Bearer {admin_token}"}
    response = requests.get(f"{BASE_URL}/api/auth/profile", headers=headers)

    if response.status_code == 200:
        print_success("Profil admin récupéré")
        user = response.json()['user']
        jwt_data = response.json()['jwt_data']
        print_info(f"Email: {user['email']}, Rôle: {user['role']}")
        print_info(f"JWT Role: {jwt_data['role']}")
        return True
    else:
        print_error("Échec")
        return False

def run_all_tests():
    """Exécuter tous les tests"""
    print(f"\n{Color.BLUE}{'🧪'*25}")
    print("   TESTS COMPLETS API e-PediCare")
    print(f"{'🧪'*25}{Color.END}\n")

    tests = [
        ("Routes de base", [
            test_1_index,
            test_2_health,
        ]),
        ("Inscription", [
            test_3_register_parent,
            test_4_register_expert,
            test_5_register_invalid_role,
            test_6_register_missing_fields,
        ]),
        ("Connexion", [
            test_7_login_parent,
            test_8_login_wrong_password,
            test_9_login_nonexistent_user,
        ]),
        ("Profil et authentification", [
            test_10_profile_with_token,
            test_11_profile_without_token,
            test_12_profile_invalid_token,
            test_13_check_auth_with_token,
            test_14_check_auth_without_token,
        ]),
        ("Admin", [
            test_15_login_admin,
            test_16_admin_profile,
        ])
    ]

    all_results = []

    for category, category_tests in tests:
        print(f"\n{Color.YELLOW}{'─'*50}")
        print(f"  {category.upper()}")
        print(f"{'─'*50}{Color.END}")

        for test in category_tests:
            try:
                result = test()
                all_results.append(result)
            except Exception as e:
                print_error(f"ERREUR: {e}")
                all_results.append(False)

    # Résumé
    print(f"\n{Color.BLUE}{'='*50}")
    print("RÉSUMÉ FINAL")
    print(f"{'='*50}{Color.END}")

    passed = sum(all_results)
    total = len(all_results)

    print(f"\nTests réussis: {Color.GREEN}{passed}{Color.END}/{total}")

    if passed == total:
        print(f"\n{Color.GREEN}{'🎉'*3} TOUS LES TESTS SONT PASSÉS ! {'🎉'*3}{Color.END}")
    else:
        failed = total - passed
        print(f"\n{Color.YELLOW}⚠️  {failed} test(s) ont échoué{Color.END}")

    print()

if __name__ == "__main__":
    run_all_tests()