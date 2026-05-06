import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class ServicoNotificacoes {
  static final FlutterLocalNotificationsPlugin _notificacoes =
      FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    tz.initializeTimeZones();

    try {
      final timezoneAtual = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneAtual.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const configuracoes = InitializationSettings(
      android: android,
    );

    await _notificacoes.initialize(configuracoes);

    final androidPlugin =
        _notificacoes.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> agendarNotificacaoDiaria({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime horario,
  }) async {
    final horarioAgendado = tz.TZDateTime.from(horario, tz.local);

    await _notificacoes.zonedSchedule(
      id,
      titulo,
      corpo,
      horarioAgendado,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicamentos_channel_v2',
          'Lembretes de medicamentos',
          channelDescription:
              'Notificações para lembrar medicamentos por refeição.',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelarTodas() async {
    await _notificacoes.cancelAll();
  }
}