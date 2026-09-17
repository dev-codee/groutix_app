class ApiEndpoints {
  static const String login = '/api/admin/login';
  static const String logout = '/api/admin/logout';
  
  static const String submissions = '/api/admin/submissions';
  static String submissionDetail(String id) => '/api/admin/submissions/$id';
  static String submissionPhotos(String id) => '/api/admin/submissions/$id/photos';
  static String leadCall(String id) => '/api/admin/lead/$id/call';
  static String leadEmail(String id) => '/api/admin/lead/$id/email';
  static String leadSms(String id) => '/api/admin/lead/$id/sms';
  static String bookingLink(String id) => '/api/admin/booking-link/$id';
  
  static const String onTheWay = '/api/admin/on-the-way';
  static const String sendInvoice = '/api/admin/invoice/send';
  static const String sendWarranty = '/api/admin/warranty/send';
  static const String sendQuote = '/api/admin/quote/send';
  
  static const String tasks = '/api/admin/tasks';
  static String taskDetail(String id) => '/api/admin/tasks/$id';
  
  static const String stats = '/api/admin/stats';
  static const String technicians = '/api/admin/technicians';
  static const String staff = '/api/admin/staff';
  static const String teamMessages = '/api/admin/team-messages';
}

