# Sprint 05 — Integration With Core APIs

> **Project:** Construction ERP  
> **Sprint:** S05  
> **Period:** 2026-08-31 to 2026-09-11  
> **Lead:** Tech Lead  
> **Goal:** Add file attachment management for projects and export support for reports (CSV) and project summaries (PDF-ready).  
> **Source:** Construction ERP Software Requirements & Technical Documentation v1.0  
> **Status:** Developer Specification

## 1. Integration Map

| Caller | Endpoint | Sprint 05 Backend | Notes |
| --- | --- | --- | --- |
| Flutter Files feature | `POST /files/upload` | `files.py` | Dio multipart |
| Flutter Files feature | `GET /files/{id}` | `files.py` | response bytes → save |
| Flutter Files feature | `DELETE /files/{id}` | `files.py` | confirm dialog |
| Flutter Files feature | `GET /files?project_id=` | `files.py` | list in project detail |
| Flutter Reports screen | `GET /export/reports?type=&format=csv` | `export.py` | download + save |
| Flutter Project detail | `GET /export/projects/{id}` | `export.py` | preview / future PDF |
| Backend ExportService | `ReportRepository` (Sprint 04) | `export.py` | reuse aggregations |
| Backend FileService | `projects` table (Sprint 01) | `files.py` | FK validation |

## 2. Frontend Integration — Dio Multipart Upload

```dart
Future<FileMetadata> uploadFile({
  required String projectId,
  required File file,
  required String category,
}) async {
  final bytes = await file.readAsBytes();
  final form = FormData.fromMap({
    'project_id': projectId,
    'category': category,
    'file': MultipartFile.fromBytes(bytes, filename: file.path.split(Platform.pathSeparator).last),
  });
  final res = await _dio.post(
    Endpoints.filesUpload,
    data: form,
    options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    onSendProgress: (sent, total) {
      // update Riverpod upload progress state
    },
  );
  if (res.data['success'] != true) throw ApiException(res.data);
  return FileMetadata.fromJson(res.data['data']);
}
```

Notes:
- JWT injected by existing Dio interceptor (Sprint 01).
- `onSendProgress` surfaces a progress bar for files > 1 MB.
- On `413` / `400`, map `errors[].code` to a user-facing message (see `04_Frontend_Developer_Guide.md`).

## 3. Frontend Integration — Download (Bytes + File Save)

```dart
Future<String> downloadFile(String fileId, String fileName) async {
  final res = await _dio.get(
    '${Endpoints.filesBase}/$fileId',
    options: Options(responseType: ResponseType.bytes),
  );
  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}/${fileId}_${fileName}';
  await File(path).writeAsBytes(res.data);
  return path;
}
```

On mobile, also save to a shared location and optionally trigger `Share.open(path)`. On web, use a Blob + anchor download.

## 4. Frontend Integration — CSV Export

```dart
Future<String> exportReportCsv(String reportType) async {
  final res = await _dio.get(
    Endpoints.exportReports,
    queryParameters: {'type': reportType, 'format': 'csv'},
    options: Options(responseType: ResponseType.bytes),
  );
  final dir = await getApplicationDocumentsDirectory();
  final filename = '${reportType}_${DateTime.now().toIso8601String().substring(0,10)}.csv';
  final path = '${dir.path}/$filename';
  await File(path).writeAsBytes(res.data);
  return path;
}
```

Show a SnackBar with the saved path and an "Open" action.

## 5. Frontend Integration — Project Export Payload

```dart
Future<ProjectExportPayload> exportProject(String projectId) async {
  final res = await _dio.get('${Endpoints.exportProject}/$projectId');
  return ProjectExportPayload.fromJson(res.data['data']);
}
```

Display in a read-only summary screen; a future Phase 2 renders it as PDF.

## 6. Backend Integration — Reusing Sprint 04 Reports

`ExportService.export_report_csv(type)` calls `ReportRepository` exactly as the Sprint 04 `/reports/{type}` endpoint does. This guarantees CSV content matches on-screen report data.

```python
# app/services/export_service.py
async def export_report_csv(self, report_type: str) -> StreamingResponse:
    rows = await self.report_repo.aggregate(report_type)
    return StreamingResponse(
        self._csv_stream(rows, report_type),
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="{report_type}.csv"'},
    )
```

## 7. Backend Integration — Project Cascade

`files.project_id` is FK to `projects.id` with `ON DELETE CASCADE`. Deleting a project removes file metadata; the service registers a post-delete hook (or a weekly cleanup job) to remove orphaned disk files.

## 8. Endpoint Registration

In `app/main.py`:

```python
from app.routers import files, export
app.include_router(files.router, prefix="/api/v1", tags=["files"])
app.include_router(export.router, prefix="/api/v1", tags=["export"])
```

## 9. Cross-Module Validation

| Check | Owner |
| --- | --- |
| `project_id` referenced by upload exists | `FileService` → `ProjectRepository.get` |
| Report type supported by CSV export | `ExportService` (same enum as Sprint 04) |
| JWT valid on every new endpoint | `require_admin` dependency |
| Response envelope matches Sprint 01 standard | router tests |

## 10. Backward Compatibility

Sprint 05 adds endpoints and one table; it does **not** modify any existing endpoint, schema, or table. No regression risk for Sprints 01–04.