import 'package:freezed_annotation/freezed_annotation.dart';

part 'share_link.freezed.dart';
part 'share_link.g.dart';

/// `POST /api/lists/{id}/shares` response (201): one share link.
///
/// The server payload has no `list_id` key — token/permission/url only
/// (DESIGN.md §2.2). `url` is the JS PWA route displayed verbatim.
@freezed
abstract class ShareLink with _$ShareLink {
  const factory ShareLink({
    required String token,
    required String permission,
    required String url,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ShareLink;

  factory ShareLink.fromJson(Map<String, dynamic> json) =>
      _$ShareLinkFromJson(json);
}
