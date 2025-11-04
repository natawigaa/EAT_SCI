import 'package:eatscikmitl/rootScreen.dart';
import 'package:eatscikmitl/screen/auth/LoginScreen.dart';
import 'package:eatscikmitl/services/supabase_service.dart';
// import 'package:eatscikmitl/dashboard/Restuarant_dashboard.dart'; // ⬅️ เวอร์ชั่นเก่า
import 'package:eatscikmitl/dashboard/restaurant_dashboard_v2.dart'; // ⬅️ เวอร์ชั่นใหม่
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://psthxmteeqczrviisdgn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzdGh4bXRlZXFjenJ2aWlzZGduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyMjAzNDEsImV4cCI6MjA3NDc5NjM0MX0.ooUYIwFUwDy_1WTRDvzm2NSr0pc-l4qEvw_vW9BcRi8',
  );
  
  // 🔧 FORCE LOGOUT - ลบบรรทัดนี้หลังสมัครสมาชิกสำเร็จแล้ว
  await Supabase.instance.client.auth.signOut();
  print('🔓 Force logout - session cleared');
  
  print('***** Supabase init completed *****');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eat@Sci',
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // แสดง loading ขณะรอ auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // ตรวจสอบว่ามี user login อยู่หรือไม่
          final session = snapshot.hasData ? snapshot.data!.session : null;
          
          if (session != null) {
            // มี session = login แล้ว
            final email = session.user.email ?? '';
            print('✅ User logged in: $email');
            
            // ตรวจสอบว่าเป็นนักศึกษาหรือร้านค้า
            return FutureBuilder<Widget>(
              future: _determineHomePage(email, session.user.id),
              builder: (context, futureSnapshot) {
                if (futureSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('กำลังโหลด...'),
                        ],
                      ),
                    ),
                  );
                }
                
                if (futureSnapshot.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Text('Error: ${futureSnapshot.error}'),
                    ),
                  );
                }
                
                return futureSnapshot.data ?? const LoginScreen();
              },
            );
          } else {
            // ไม่มี session = ยังไม่ login
            print('❌ No session - show LoginScreen');
            return const LoginScreen();
          }
        },
      ),
      theme: ThemeData(
        primaryColor: Theme.of(context).scaffoldBackgroundColor
      ),
    );
  }

  // ฟังก์ชันตรวจสอบว่าเป็นนักศึกษาหรือร้านค้า
  Future<Widget> _determineHomePage(String email, String userId) async {
    // 1. เช็คว่าเป็นนักศึกษา KMITL หรือไม่
    if (email.endsWith('@kmitl.ac.th')) {
      print('👨‍🎓 นักศึกษา KMITL → RootScreen');
      return const RootScreen(currentScreens: 1);
    }
    
    // 2. ถ้าไม่ใช่นักศึกษา → เช็คว่าเป็นร้านค้าไหม (หา owner_id)
    print('🏪 ไม่ใช่นักศึกษา → เช็คร้านค้า...');
    try {
      final restaurants = await SupabaseService.getRestaurants();
      final myRestaurant = restaurants.firstWhere(
        (r) => r['owner_id'] == userId,
        orElse: () => {},
      );
      
      if (myRestaurant.isNotEmpty) {
        print('✅ พบร้าน: ${myRestaurant['name']} (ID: ${myRestaurant['id']})');
        
        // ⬇️ เวอร์ชั่นใหม่ (V2)
        return RestaurantDashboardV2(
          restaurantId: myRestaurant['id'].toString(),
          restaurantName: myRestaurant['name'],
        );
        
        // ⬇️ เวอร์ชั่นเก่า (คอมเม้นไว้)
        // return RestaurantDashboardScreen(
        //   restaurantId: myRestaurant['id'].toString(),
        //   restaurantName: myRestaurant['name'],
        // );
      } else {
        print('❌ ไม่พบร้านที่เชื่อมกับ user นี้');
        // ถ้าไม่เจอร้าน → ส่งกลับไป LoginScreen
        return const LoginScreen();
      }
    } catch (e) {
      print('❌ Error checking restaurant: $e');
      return const LoginScreen();
    }
  }
}