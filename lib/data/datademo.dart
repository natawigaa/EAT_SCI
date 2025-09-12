class DataDemo {
  // ข้อมูลร้านอาหารในโรงอาหารคณะวิทยาศาสตร์
  static List<Map<String, dynamic>> restaurants = [
    {
      'restaurantId': 'shop_001',
      'restaurantName': 'ร้านป้าสมใส',
      'restaurantImage': 'assets/images/restaurant_pasom.jpg',
      'phone': '088-888-8888',
      'category': 'อาหารตามสั่ง',
      'description': 'อาหารตามสั่งรสชาติดั้งเดิม ราคาประหยัด',
      'rating': 4.3,
      'openTime': '07:00',
      'closeTime': '15:00',
      'location': 'โซน A',
      'menuItems': [
        {
          'itemId': 'item_001',
          'imgUrl': 'assets/images/pad_kra_pao_gai.jpg',
          'foodname': 'ผัดกะเพราไก่',
          'price': 40,
          'description': 'ผัดกะเพราไก่สับเผ็ดร้อน ไข่ดาวกรอบ',
          'isPopular': true,
        },
        {
          'itemId': 'item_002',
          'imgUrl': 'assets/images/pad_kra_pao_moo.jpg',
          'foodname': 'ผัดกะเพราหมู',
          'price': 40,
          'description': 'ผัดกะเพราหมูสับเผ็ดหอม ไข่ดาว',
          'isPopular': true,
        },
        {
          'itemId': 'item_003',
          'imgUrl': 'assets/images/khao_pad_gai.jpg',
          'foodname': 'ข้าวผัดไก่',
          'price': 35,
          'description': 'ข้าวผัดไก่หอมๆ พร้อมผัก',
          'isPopular': false,
        },
        {
          'itemId': 'item_004',
          'imgUrl': 'assets/images/pad_pak_bung.jpg',
          'foodname': 'ผัดผักบุ้งไฟแดง',
          'price': 35,
          'description': 'ผักบุ้งผัดไฟแดงเผ็ดร้อน',
          'isPopular': false,
        },
      ]
    },

    {
      'restaurantId': 'shop_002',
      'restaurantName': 'ร้านก๋วยเตี๋ยวลุงบุญ',
      'restaurantImage': 'assets/images/restaurant_uncle_boon.jpg',
      'phone': '088-888-8888',
      'category': 'ก๋วยเตี๋ยว',
      'description': 'ก๋วยเตี๋ยวน้ำใส น้ำข้น รสชาติเข้มข้น',
      'rating': 4.1,
      'openTime': '06:30',
      'closeTime': '14:30',
      'location': 'โซน B',
      'menuItems': [
        {
          'itemId': 'item_005',
          'imgUrl': 'assets/images/kuay_teow_nam_moo.jpg',
          'foodname': 'ก๋วยเตี๋ยวน้ำหมู',
          'price': 35,
          'description': 'เส้นเล็ก น้ำใส หมูสับ ลูกชิ้น',
          'isPopular': true,
        },
        {
          'itemId': 'item_006',
          'imgUrl': 'assets/images/kuay_teow_nam_gai.jpg',
          'foodname': 'ก๋วยเตี๋ยวน้ำไก่',
          'price': 35,
          'description': 'เส้นเล็ก น้ำใส เนื้อไก่นุ่ม',
          'isPopular': false,
        },
        {
          'itemId': 'item_007',
          'imgUrl': 'assets/images/kuay_teow_tom_yum.jpg',
          'foodname': 'ก๋วยเตี๋ยวต้มยำ',
          'price': 40,
          'description': 'ก๋วยเตี๋ยวต้มยำเผ็ดร้อน กุ้งสด',
          'isPopular': true,
        },
        {
          'itemId': 'item_008',
          'imgUrl': 'assets/images/bamee_moo_dang.jpg',
          'foodname': 'บะหมี่หมูแดง',
          'price': 38,
          'description': 'บะหมี่เส้นเหลือง หมูแดงหวาน',
          'isPopular': false,
        },
      ]
    },

    {
      'restaurantId': 'shop_003',
      'restaurantName': 'ข้าวมันไก่ป้าเล็ก',
      'restaurantImage': 'assets/images/restaurant_khao_man_gai.jpg',
      'phone': '088-888-8888',
      'category': 'ข้าวมันไก่',
      'description': 'ข้าวมันไก่รสเด็ด น้ำจิ้มเข้มข้น',
      'rating': 4.7,
      'openTime': '08:00',
      'closeTime': '15:00',
      'location': 'โซน A',
      'menuItems': [
        {
          'itemId': 'item_009',
          'imgUrl': 'assets/images/khao_man_gai_tom.jpg',
          'foodname': 'ข้าวมันไก่ต้ม',
          'price': 40,
          'description': 'ข้าวมันไก่ต้มนุ่ม น้ำจิ้มรสเด็ด',
          'isPopular': true,
        },
        {
          'itemId': 'item_010',
          'imgUrl': 'assets/images/khao_man_gai_tod.jpg',
          'foodname': 'ข้าวมันไก่ทอด',
          'price': 45,
          'description': 'ข้าวมันไก่ทอดกรอบ หนังไก่กรุบกรอบ',
          'isPopular': true,
        },
        {
          'itemId': 'item_011',
          'imgUrl': 'assets/images/khao_man_gai_ruam.jpg',
          'foodname': 'ข้าวมันไก่รวม',
          'price': 50,
          'description': 'ข้าวมันไก่ทั้งต้มและทอด',
          'isPopular': false,
        },
      ]
    },

    {
      'restaurantId': 'shop_004',
      'restaurantName': 'ร้านอีสานป้าจิ๋ว',
      'restaurantImage': 'assets/images/restaurant_isaan.jpg',
      'phone': '088-888-8888',
      'category': 'อาหารอีสาน',
      'description': 'อาหารอีสานรสจัด เผ็ดร้อนต้นตำรับ',
      'rating': 4.4,
      'openTime': '10:00',
      'closeTime': '19:00',
      'location': 'โซน C',
      'menuItems': [
        {
          'itemId': 'item_012',
          'imgUrl': 'assets/images/som_tam_thai.jpg',
          'foodname': 'ส้มตำไทย',
          'price': 30,
          'description': 'ส้มตำไทยรสหวานเผ็ด ถั่วลิสง',
          'isPopular': true,
        },
        {
          'itemId': 'item_013',
          'imgUrl': 'assets/images/som_tam_poo.jpg',
          'foodname': 'ส้มตำปู',
          'price': 35,
          'description': 'ส้มตำปูม้าเผ็ดจี๊ดจ๊าด',
          'isPopular': false,
        },
        {
          'itemId': 'item_014',
          'imgUrl': 'assets/images/larb_moo.jpg',
          'foodname': 'ลาบหมู',
          'price': 40,
          'description': 'ลาบหมูเผ็ดร้อน เครื่องเทศหอม',
          'isPopular': true,
        },
        {
          'itemId': 'item_015',
          'imgUrl': 'assets/images/nam_tok_moo.jpg',
          'foodname': 'น้ำตกหมู',
          'price': 45,
          'description': 'น้ำตกหมูย่างเผ็ดร้อน',
          'isPopular': false,
        },
      ]
    },

    {
      'restaurantId': 'shop_005',
      'restaurantName': 'ร้านเครื่องดื่ม Uncle Coffee',
      'restaurantImage': 'assets/images/restaurant_coffee.jpg',
      'phone': '088-888-8888',
      'category': 'เครื่องดื่ม',
      'description': 'กาแฟสด ชา น้ำผลไม้ รสชาติเยี่ยม',
      'rating': 4.0,
      'openTime': '07:00',
      'closeTime': '17:00',
      'location': 'โซน B',
      'menuItems': [
        {
          'itemId': 'item_016',
          'imgUrl': 'assets/images/thai_coffee_iced.jpg',
          'foodname': 'กาแฟไทยเย็น',
          'price': 25,
          'description': 'กาแฟไทยเย็นหวานมัน สีส้มสวย',
          'isPopular': true,
        },
        {
          'itemId': 'item_017',
          'imgUrl': 'assets/images/thai_tea_iced.jpg',
          'foodname': 'ชาไทยเย็น',
          'price': 20,
          'description': 'ชาไทยเย็นสีส้ม หวานหอม',
          'isPopular': true,
        },
        {
          'itemId': 'item_018',
          'imgUrl': 'assets/images/fresh_orange.jpg',
          'foodname': 'น้ำส้มคั้นสด',
          'price': 30,
          'description': 'น้ำส้มคั้นสดใหม่ วิตามินซีสูง',
          'isPopular': false,
        },
        {
          'itemId': 'item_019',
          'imgUrl': 'assets/images/americano_iced.jpg',
          'foodname': 'อเมริกาโน่เย็น',
          'price': 35,
          'description': 'กาแฟอเมริกาโน่เย็นเข้มข้น',
          'isPopular': false,
        },
      ]
    },

    {
      'restaurantId': 'shop_006',
      'restaurantName': 'ของหวานป้านิด',
      'restaurantImage': 'assets/images/restaurant_dessert.jpg',
      'phone': '088-888-8888',
      'category': 'ของหวาน',
      'description': 'ของหวานไทยโบราณ รสชาติหวานหอม',
      'rating': 4.5,
      'openTime': '11:00',
      'closeTime': '18:00',
      'location': 'โซน C',
      'menuItems': [
        {
          'itemId': 'item_020',
          'imgUrl': 'assets/images/khao_niao_mamuang.jpg',
          'foodname': 'ข้าวเหนียวมะม่วง',
          'price': 35,
          'description': 'ข้าวเหนียวหวาน มะม่วงสุกหวาน',
          'isPopular': true,
        },
        {
          'itemId': 'item_021',
          'imgUrl': 'assets/images/tub_tim_grob.jpg',
          'foodname': 'ทับทิมกรอบ',
          'price': 25,
          'description': 'ทับทิมกรอบเย็นชื่นใจ',
          'isPopular': false,
        },
        {
          'itemId': 'item_022',
          'imgUrl': 'assets/images/bua_loy.jpg',
          'foodname': 'บัวลอยน้ำกะทิ',
          'price': 30,
          'description': 'บัวลอยสีสวย น้ำกะทิหวานหอม',
          'isPopular': true,
        },
        {
          'itemId': 'item_023',
          'imgUrl': 'assets/images/khanom_krok.jpg',
          'foodname': 'ขนมครก',
          'price': 20,
          'description': 'ขนมครกกรอบนอกนุ่มใน (6 ลูก)',
          'isPopular': false,
        },
      ]
    },
  ];

  // ฟังก์ชันช่วยในการดึงข้อมูล
  static List<Map<String, dynamic>> getRestaurantsByCategory(String category) {
    return restaurants.where((restaurant) => restaurant['category'] == category).toList();
  }

  static Map<String, dynamic>? getRestaurantById(String restaurantId) {
    try {
      return restaurants.firstWhere((restaurant) => restaurant['restaurantId'] == restaurantId);
    } catch (e) {
      return null;
    }
  }

  static List<Map<String, dynamic>> getPopularItems(String restaurantId) {
    final restaurant = getRestaurantById(restaurantId);
    if (restaurant == null) return [];
    
    final menuItems = restaurant['menuItems'] as List<Map<String, dynamic>>;
    return menuItems.where((item) => item['isPopular'] == true).toList();
  }

  static List<Map<String, dynamic>> getAllCategories() {
    final categories = <String>{};
    for (var restaurant in restaurants) {
      categories.add(restaurant['category']);
    }
    return categories.map((category) => {'name': category}).toList();
  }
}