# app_pacientes

App Flutter para el catálogo de pacientes. Consume la API de [api_pacientes](https://github.com/CristianMares/api_pacientes).

## Funciones

- Alta, consulta y edición de pacientes
- Cancelar y reactivar (cambia el estatus, no borra)
- Búsqueda por nombre o apellidos y filtro por estatus
- IMC automático con categoría
- Exportar la lista a PDF o CSV

## APK

Se compila en cada push. Descargar `app_pacientes.apk` desde Releases.

## Correr local

```
flutter pub get
flutter run
```

La dirección de la API se configura desde el engrane de la pantalla principal.
