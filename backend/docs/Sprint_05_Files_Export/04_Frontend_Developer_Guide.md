# Sprint 05 — Frontend Developer Guide

> **Project:** Construction ERP  
> **Sprint:** S05  
> **Period:** 2026-08-31 to 2026-09-11  
> **Lead:** Tech Lead  
> **Goal:** Add file attachment management for projects and export support for reports (CSV) and project summaries (PDF-ready).  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Feature Layout

New feature-first module under `lib/features/files/`, plus export actions wired into the existing `lib/features/reports/` presentation.

```
lib/features/files/
  data/
    file_remote_datasource.dart   # Dio multipart upload, download (bytes), delete, list
    file_repository_impl.dart
    models/
      file_metadata_model.dart
  domain/
    entities/
      file_entity.dart
    repositories/
      file_repository.dart
    usecases/
      upload_file.dart
      download_file.dart
      delete_file.dart
      list_project_files.dart
  presentation/
    controllers/
      file_controller.dart         # Riverpod StateNotifier
    screens/
      project_files_tab.dart       # embedded in project detail
    widgets/
      file_upload_button.dart
      file_list_table.dart
      file_download_button.dart
      delete_file_dialog.dart
```

Add to `lib/core/constants/endpoints.dart`:

```dart
class Endpoints {
  // ... existing ...
  static const String filesUpload   = '/files/upload';
  static const String filesBase     = '/files';        // /files/{id}, /files?project_id=
  static const String exportReports = '/export/reports'; // ?type=&format=csv
  static const String exportProject = '/export/projects'; // /export/projects/{id}
}
```

## 2. Upload — Multipart via Dio

```dart
Future<FileMetadata> uploadFile({
  required String projectId,
  required File file,
  required String category,
}) async {
  final form = FormData.fromMap({
    'project_id': projectId,
    'category': category,
    'file': MultipartFile.fromBytes(
      await file.readAsBytes(),
      filename: file.path.split('/').last,
    ),
  });
  final res = await _dio.post(Endpoints.filesUpload, data: form);
  return FileMetadata.fromJson(res.data['data']);
}
```

Notes:
- Set `options.headers` to `multipart/form-data` (Dio handles it when `FormData` is used).
- Attach JWT bearer via interceptor (already configured Sprint 01).
- Surface upload progress via `onSendProgress` for files > 1 MB.

## 3. Download — Bytes + Platform Save

```dart
Future<void> downloadFile(String fileId, String fileName) async {
  final res = await _dio.get(
    '${Endpoints.filesBase}/$fileId',
    options: Options(responseType: ResponseType.bytes),
  );
  final dir = await getApplicationDocumentsDirectory(); // path_provider
  final savePath = '${dir.path}/$fileName';
  await File(savePath).writeAsBytes(res.data);
  // optionally trigger platform share / open
}
```

For mobile, also register a file provider so the OS can open the saved file. For web, use a Blob download approach.

## 4. Export — CSV and Project Payload

### CSV Export (reports screen)

```dart
Future<void> exportReportCsv(String reportType) async {
  final res = await _dio.get(
    Endpoints.exportReports,
    queryParameters: {'type': reportType, 'format': 'csv'},
    options: Options(responseType: ResponseType.bytes),
  );
  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}/${reportType}_${DateTime.now().millisecondsSinceEpoch}.csv';
  await File(path).writeAsBytes(res.data);
  // show SnackBar with path / open
}
```

### Project Export Payload (project detail)

```dart
Future<ProjectExportPayload> exportProject(String projectId) async {
  final res = await _dio.get('${Endpoints.exportProject}/$projectId');
  return ProjectExportPayload.fromJson(res.data['data']);
}
```

The payload is displayed in a preview screen or handed to a future PDF renderer.

## 5. State Management (Riverpod)

```dart
final fileControllerProvider = StateNotifierProvider<FileController, AsyncValue<List<FileMetadata>>>((ref) {
  return FileController(ref.read(fileRepositoryProvider));
});

class FileController extends StateNotifier<AsyncValue<List<FileMetadata>>> {
  Future<void> load(String projectId) async { ... }
  Future<void> upload(String projectId, File file, String category) async { ... }
  Future<void> delete(String fileId) async { ... }
}
```

States follow the existing pattern:
- **loading** — spinner / shimmer.
- **empty** — "No files attached yet" + upload button.
- **error** — error banner with retry.
- **data** — table of files.

## 6. UI Wiring

| Screen | Action | Trigger |
| --- | --- | --- |
| Project detail → Files tab | Upload | `FilePicker` → category dropdown → POST `/files/upload` |
| Project detail → Files tab | Download | tap row → GET `/files/{id}` → save |
| Project detail → Files tab | Delete | long-press → confirm dialog → DELETE `/files/{id}` |
| Reports screen | CSV export | button per report type → GET `/export/reports?type=&format=csv` |
| Project detail | Project export | "Export Summary" button → GET `/export/projects/{id}` → preview |

## 7. Error Handling

- `413` → "File too large (max 25 MB)".
- `400 INVALID_FILE_TYPE` → "Unsupported file type. Allowed: pdf, png, jpg, jpeg, xlsx, docx, csv".
- `404` → "File not found" (it may have been deleted).
- Network error → existing `DioException` handler in `lib/core/network/`.

## 8. Accessibility & UX

- Upload button disabled while uploading; progress indicator.
- Delete confirmation dialog to prevent accidental removal.
- File sizes shown in human-readable form (KB / MB) via a formatter.
- Table rows are tappable; download icon button on each row.