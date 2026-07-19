// ResearchScope là nơi quyết định app lọc bài báo thế nào. Bất biến quan trọng
// nhất: MỌI phạm vi đều sinh ra filter theo cây phân loại (primary_topic.*),
// KHÔNG bao giờ dùng search= full-text — đó là thứ giữ cho số liệu đúng phạm vi
// thay vì phình thành tổng của OpenAlex.
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/models/research_scope.dart';
import 'package:journal_trend_analyzer/models/research_field.dart';

void main() {
  test('field scope lọc theo primary_topic.field.id', () {
    const scope = ResearchScope.field(id: '17', label: 'Computer Science');
    expect(scope.filterFragment, 'primary_topic.field.id:17');
  });

  test('subfield scope lọc theo primary_topic.subfield.id', () {
    const scope = ResearchScope.subfield(
      id: '1712',
      label: 'Software',
      parentLabel: 'Computer Science',
    );
    expect(scope.filterFragment, 'primary_topic.subfield.id:1712');
    expect(scope.fullLabel, 'Computer Science › Software');
  });

  test('topic scope lọc theo primary_topic.id', () {
    const scope = ResearchScope.topic(
      id: 'T10270',
      label: 'Blockchain',
      parentLabel: 'Computer Science › Information Systems',
    );
    expect(scope.filterFragment, 'primary_topic.id:T10270');
  });

  test('TopicSuggestion.toScope dựng breadcrumb từ field + subfield', () {
    final suggestion = TopicSuggestion.fromJson({
      'id': 'https://openalex.org/T10270',
      'display_name': 'Blockchain Technology Applications and Security',
      'subfield': {'display_name': 'Information Systems'},
      'field': {'display_name': 'Computer Science'},
      'works_count': 150556,
    });

    // ID phải cắt phần URL, chỉ giữ "T10270" để ghép vào filter.
    expect(suggestion.id, 'T10270');
    expect(suggestion.breadcrumb, 'Computer Science › Information Systems');

    final scope = suggestion.toScope();
    expect(scope.kind, ScopeKind.topic);
    expect(scope.filterFragment, 'primary_topic.id:T10270');
    expect(scope.parentLabel, 'Computer Science › Information Systems');
  });
}
