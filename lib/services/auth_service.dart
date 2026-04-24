import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Check if logged-in user is police
  Future<bool> isPolice() async {
    User? user = _auth.currentUser;
    if (user == null) return false;
    
    // Method 1: Check by email domain
    if (user.email?.contains('@police.gov.pk') == true) {
      return true;
    }
    
    // Method 2: Check Firestore user collection
    // (You'll implement this)
    
    return false;
  }
  
  // Get current user role
  Future<String> getUserRole() async {
    User? user = _auth.currentUser;
    if (user == null) return 'none';
    
    if (user.email?.contains('@police.gov.pk') == true) {
      return 'police';
    }
    return 'citizen';
  }
}