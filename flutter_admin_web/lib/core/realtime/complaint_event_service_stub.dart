import '../network/api_client.dart';

class ComplaintEventService {
  ComplaintEventService(this.api);

  final ApiClient api;

  Future<void> start({required void Function() onEvent}) async {}

  void close() {}
}
