import 'package:permission_handler/permission_handler.dart';

/// Un servicio para manejar las solicitudes de permisos de la aplicación.
class PermissionService {
  /// Solicita todos los permisos necesarios para el funcionamiento principal de la app.
  ///
  /// Pide permisos para la cámara, el reconocimiento de actividad física y los sensores.
  /// Devuelve `true` si todos los permisos fueron concedidos, `false` en caso contrario.
  Future<bool> requestCorePermissions() async {
    // Un mapa de los permisos que nuestra aplicación necesita.
    final permissions = <Permission>[
      Permission.camera,
      Permission.activityRecognition,
      Permission.sensors,
    ];

    // Solicita los permisos al usuario.
    final Map<Permission, PermissionStatus> statuses =
        await permissions.request();

    // Verifica si todos los permisos solicitados fueron concedidos.
    // Usamos `every` para asegurarnos de que cada estado en el mapa sea `granted`.
    final allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      // Todos los permisos fueron concedidos.
      return true;
    } else {
      // Al menos un permiso fue denegado.
      // Aquí podrías mostrar un diálogo al usuario explicando por qué los
      // permisos son necesarios y ofrecerle abrirlos en la configuración del sistema.
      // Por ejemplo:
      // await _showPermissionDeniedDialog();
      return false;
    }
  }

  /// Abre la configuración de la aplicación para que el usuario pueda
  /// cambiar los permisos manualmente.
  Future<void> openAppSettings() async {
    await openAppSettings(); // Esto es una llamada a la función del paquete permission_handler
  }

  /// Comprueba el estado de un permiso específico.
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return await permission.status;
  }
}