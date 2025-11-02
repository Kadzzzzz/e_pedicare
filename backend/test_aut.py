"""
Script de test simple pour l'authentification e-PediCare
Lance le serveur avant d'exécuter ce script : python app.py
"""

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

def test_1_hello():
    """Test de connexion au serveur"""
    print_test("1. Connexion au serveur")

    try:
        response = requests.get(f"{BASE_URL}/api/hello")

        if response.status_code == 200:
            print_success("Serveur accessible")
            print_info(f"Réponse: {response.json()['message']}")
            return True
        else:
            print_error("Serveur inaccessible")
            return False
    except:
        print_error("Impossible de se connecter au serveur")
        print_info("Vérifiez que le serveur est démarré: python app.py")
        return False

def test_2_register():
    """Créer un nouveau compte"""
    print_test("2. Créer un compte parent")

    data = {
        "email": "test_auto@test.fr",
        "password": "password123",
        "role": "parent"
    }

    response = requests.post(f"{BASE_URL}/api/auth/register", json=data)

    if response.status_code == 201:
        print_success("Compte créé avec succès")
        user = response.json()['user']
        print_info(f"Email: {user['email']}, Rôle: {user['role']}")
        return True
    elif response.status_code == 409:
        print_info("Compte existe déjà (normal si déjà testé)")
        return True
    else:
        print_error(f"Échec de la création: {response.json()}")
        return False

def test_3_login():
    """Se connecter"""
    global token
    print_test("3. Se connecter avec le compte créé")

    data = {
        "email": "test_auto@test.fr",
        "password": "password123"
    }

    response = requests.post(f"{BASE_URL}/api/auth/login", json=data)

    if response.status_code == 200:
        print_success("Connexion réussie")
        token = response.json()['access_token']
        print_info(f"Token reçu: {token[:30]}...")
        return True
    else:
        print_error(f"Échec de la connexion: {response.json()}")
        return False

def test_4_login_wrong_password():
    """Connexion avec mauvais mot de passe"""
    print_test("4. Connexion avec mauvais mot de passe")

    data = {
        "email": "test_auto@test.fr",
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

def test_5_profile_with_token():
    """Accéder au profil avec token"""
    print_test("5. Accéder au profil avec token")

    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/api/auth/profile", headers=headers)

    if response.status_code == 200:
        print_success("Profil récupéré")
        user = response.json()['user']
        print_info(f"Email: {user['email']}, Rôle: {user['role']}")
        return True
    else:
        print_error(f"Échec: {response.json()}")
        return False

def test_6_profile_without_token():
    """Accéder au profil SANS token"""
    print_test("6. Accéder au profil SANS token")

    response = requests.get(f"{BASE_URL}/api/auth/profile")

    if response.status_code == 401:
        print_success("Accès refusé sans token (normal)")
        print_info(f"Message: {response.json()['message']}")
        return True
    else:
        print_error("Accès autorisé sans token (problème!)")
        return False

def test_7_login_admin():
    """Connexion admin"""
    global token
    print_test("7. Connexion avec compte admin")

    data = {
        "email": "admin@epedicare.fr",
        "password": "admin123"
    }

    response = requests.post(f"{BASE_URL}/api/auth/login", json=data)

    if response.status_code == 200:
        print_success("Connexion admin réussie")
        token = response.json()['access_token']
        return True
    else:
        print_error("Échec de connexion admin")
        return False

def test_8_admin_zone():
    """Accéder à la zone admin"""
    print_test("8. Accéder à la zone admin")

    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/api/admin", headers=headers)

    if response.status_code == 200:
        print_success("Accès admin autorisé")
        print_info(f"Message: {response.json()['message']}")
        return True
    else:
        print_error("Accès admin refusé")
        return False

def test_9_protected_resource():
    """Accéder à une ressource protégée"""
    print_test("9. Accéder à une ressource protégée")

    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/api/protected", headers=headers)

    if response.status_code == 200:
        print_success("Ressource protégée accessible")
        print_info(f"Message: {response.json()['message']}")
        return True
    else:
        print_error("Accès refusé")
        return False

def run_all_tests():
    """Exécuter tous les tests"""
    print(f"\n{Color.BLUE}{'🧪'*25}")
    print("   TESTS D'AUTHENTIFICATION e-PediCare")
    print(f"{'🧪'*25}{Color.END}\n")

    tests = [
        test_1_hello,
        test_2_register,
        test_3_login,
        test_4_login_wrong_password,
        test_5_profile_with_token,
        test_6_profile_without_token,
        test_7_login_admin,
        test_8_admin_zone,
        test_9_protected_resource,
    ]

    results = []

    for test in tests:
        try:
            result = test()
            results.append(result)
        except Exception as e:
            print_error(f"ERREUR: {e}")
            results.append(False)

    # Résumé
    print(f"\n{Color.BLUE}{'='*50}")
    print("RÉSUMÉ")
    print(f"{'='*50}{Color.END}")

    passed = sum(results)
    total = len(results)

    print(f"\nTests réussis: {passed}/{total}")

    if passed == total:
        print(f"\n{Color.GREEN}🎉 TOUS LES TESTS SONT PASSÉS !{Color.END}")
    else:
        print(f"\n{Color.YELLOW}⚠️  {total - passed} test(s) ont échoué{Color.END}")

    print()

if __name__ == "__main__":
    run_all_tests()
