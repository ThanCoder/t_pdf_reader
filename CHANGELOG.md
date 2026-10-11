# 1.5.0

* Fixed -> `IPageImageWorkerType` with `multiThread`. error -> `android` 

# 1.4.0

### Added

* Added configurable page image worker modes with single-thread and multi-thread support.
* Added independent low- and high-quality page image processing.
* Added `IPageImageWorkerType` with `singleThread` as the default mode.


# 1.3.0

+ Refactored the PDF reader item rendering architecture.
+ Improved page image caching and rendering performance.

# 1.2.0

+ Changed `Pdf Reader Item Core.`
- Changed `PdfReloadPageView` -> `PdfPreloadPageView`

# 1.1.0

+ Added Stream -> `PageRenderImageTypeChanged`,`PageRenderImageQualityChanged`,`PreloadPageCountChanged`
+ Added Widgets -> `PdfReloadPageView`,`PdfRenderImageTypeView`,`PdfVisiablePageView`
+ Some Widget Updated.

## 1.0.0
* Completed Changed Core. `TPdfReader`,`TPdfController`
* Completed Changed `than_pdf_engine: ^1.2.0`

## 0.5.0

+ Updated `than_pdf_engine: ^0.5.0` 
- Removed `dart_core_extensions`

## 0.4.0
+ Updated `dart_core_extensions: ^0.5.0`

## 0.3.0

+ Changed `Update Engine`
+ Fixed `Known Errors.`

## 0.2.0

- Added Event `Keyboard` -> `KeyDown`,`KeyUp`
- Added `TPdfController:keyboardScrollSpeed` - Property.
- Added `TPdfController:onKeyEvent` - Function.
- Changed `mixin` -> `Interface Component` Logic.
- Fixed `Worng Pdf Page Count`

## 0.1.0

- Update `than_pdf_engine`
- Fixed `Page Footer Wiget` Scroll Error.

## 0.0.1

- initial release.
